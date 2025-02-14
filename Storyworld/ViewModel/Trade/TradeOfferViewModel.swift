//
//  TradeOfferViewModel.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI
import FirebaseAuth

import FirebaseFirestore

class TradeOfferViewModel: ObservableObject {
    @Published var offers: [TradeOffer] = []  // 받은 트레이드 요청
    @Published var tradeMap: [String: Trade] = [:] // tradeId -> Trade 매핑 저장
    @Published var userMap: [String: User] = [:]  // proposerId -> User 매핑 저장

    private let db = Firestore.firestore()

    func loadReceivedOffers() {
        guard let currentUserId = UserService.shared.user?.id else {
            print("❌ 유저 정보가 없습니다.")
            return
        }

        // `tradeOffers` 컬렉션에서 `tradeOwnerId`가 현재 사용자 ID인 거래 제안들 중, `status`가 'pending'인 것만 가져옴
        db.collectionGroup("tradeOffers")
            .whereField("tradeOwnerId", isEqualTo: currentUserId)
            .whereField("status", isEqualTo: "pending") // 상태가 'pending'인 거래만 가져옴
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 받은 요청 로딩 실패: \(error.localizedDescription)")
                    return
                }

                if let snapshot = snapshot {
                    self.offers = snapshot.documents.compactMap { document in
                        try? document.data(as: TradeOffer.self)
                    }
                    print("✅ 받은 요청 \(self.offers.count)개 로드 완료")

                    // 🔥 tradeId를 통해 Trade 정보 가져오기
                    self.loadTradeDetails()
                    
                    // 🔥 proposerId를 통해 사용자 정보 가져오기
                    self.loadProposerInfo()
                }
            }
    }

    // 🔥 Trade ID를 통해 Trade 정보 불러오기
    private func loadTradeDetails() {
        let tradeIds = Set(offers.map { $0.tradeId }) // 중복 제거

        for tradeId in tradeIds {
            db.collection("trades").document(tradeId).getDocument { document, error in
                if let error = error {
                    print("❌ Trade 정보 가져오기 실패 (\(tradeId)): \(error.localizedDescription)")
                    return
                }
                if let document = document, document.exists {
                    if let trade = try? document.data(as: Trade.self) {
                        DispatchQueue.main.async {
                            self.tradeMap[tradeId] = trade
                        }
                    }
                }
            }
        }
    }

    // 🔥 proposerId를 기반으로 Firestore에서 사용자 정보 가져오기
    private func loadProposerInfo() {
        let proposerIds = Set(offers.map { $0.proposerId }) // 중복 제거

        for proposerId in proposerIds {
            db.collection("users").document(proposerId).getDocument { document, error in
                if let error = error {
                    print("❌ 사용자 정보 가져오기 실패 (\(proposerId)): \(error.localizedDescription)")
                    return
                }
                if let document = document, document.exists {
                    if let user = try? document.data(as: User.self) {
                        DispatchQueue.main.async {
                            self.userMap[proposerId] = user
                        }
                    }
                }
            }
        }
    }
    
    // ✅ 트레이드 수락 (Accept)
    func acceptOffer(offer: TradeOffer) {
        TradeService.shared.acceptTradeOffer(offer: offer) { result in
            switch result {
            case .success:
                print("✅ 트레이드 수락 성공")
                
                // Firestore에서 tradeOffers 문서 상태를 'accepted'로 업데이트
                let db = Firestore.firestore()
                db.collection("trades")
                    .document(offer.tradeId)
                    .collection("tradeOffers")
                    .document(offer.id) // 해당 offer 문서 업데이트
                    .updateData(["status": "accepted"]) { error in
                        if let error = error {
                            print("❌ 트레이드 오퍼 상태 업데이트 실패: \(error.localizedDescription)")
                        } else {
                            print("✅ 트레이드 오퍼 상태 'accepted'로 업데이트 완료")
                        }
                    }
                
                // 해당 오퍼는 `offers`에서 삭제
                DispatchQueue.main.async {
                    self.offers.removeAll { $0.id == offer.id }
                }

            case .failure(let error):
                print("❌ 트레이드 수락 실패: \(error.localizedDescription)")
            }
        }
    }

    // ✅ 트레이드 거절 (Reject)
    func rejectOffer(offer: TradeOffer) {
        TradeService.shared.rejectTradeOffer(offer: offer) { result in
            switch result {
            case .success:
                print("❌ 트레이드 거절 성공")
                
                // Firestore에서 tradeOffers 문서 상태를 'rejected'로 업데이트
                let db = Firestore.firestore()
                db.collection("trades")
                    .document(offer.tradeId)
                    .collection("tradeOffers")
                    .document(offer.id) // 해당 offer 문서 업데이트
                    .updateData(["status": "rejected"]) { error in
                        if let error = error {
                            print("❌ 트레이드 오퍼 상태 업데이트 실패: \(error.localizedDescription)")
                        } else {
                            print("✅ 트레이드 오퍼 상태 'rejected'로 업데이트 완료")
                        }
                    }
                
                // 해당 오퍼는 `offers`에서 삭제
                DispatchQueue.main.async {
                    self.offers.removeAll { $0.id == offer.id }
                }

            case .failure(let error):
                print("❌ 트레이드 거절 실패: \(error.localizedDescription)")
            }
        }
    }

}
