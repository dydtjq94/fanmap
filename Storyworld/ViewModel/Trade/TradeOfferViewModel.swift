//
//  TradeOfferViewModel.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

class TradeOfferViewModel: ObservableObject {
    @Published var offers: [TradeOffer] = []
    @Published var userMap: [String: User] = [:] // ✅ 제안자의 유저 정보 캐싱
    
    private let db = Firestore.firestore()
    
    /// ✅ 오퍼 수락 (거래 완료)
    func acceptOffer(offer: TradeOffer) {
        guard let offerId = offer.id else { return } // ✅ `offerId`가 없으면 실행하지 않음
        
        TradeService.shared.acceptOffer(for: offer.trade, offerId: offerId) { success in
            if success {
                DispatchQueue.main.async {
                    self.offers.removeAll { $0.id == offerId } // ✅ 해당 오퍼 삭제
                }
            }
        }
    }
    
    /// ✅ 오퍼 거절 (거래 취소)
    func rejectOffer(offer: TradeOffer) {
        guard let offerId = offer.id else { return } // ✅ `offerId`가 없으면 실행하지 않음
        
        TradeService.shared.rejectOffer(for: offer.trade, offerId: offerId) { success in
            if success {
                DispatchQueue.main.async {
                    self.offers.removeAll { $0.id == offerId } // ✅ 해당 오퍼 삭제
                }
            }
        }
    }
    
    func loadReceivedOffers() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userTradesRef = db.collection("users").document(userId).collection("myTrades")
        
        userTradesRef.whereField("tradeStatus", isEqualTo: "pending").getDocuments { snapshot, error in
            if let error = error {
                print("❌ [loadReceivedOffers] 내 트레이드 가져오기 실패: \(error.localizedDescription)")
                return
            }
            
            var allOffers: [TradeOffer] = []
            let group = DispatchGroup()
            
            for document in snapshot!.documents {
                let tradeId = document.documentID
                let offersRef = userTradesRef.document(tradeId).collection("offer")
                
                group.enter()
                offersRef.getDocuments { offerSnapshot, offerError in
                    if let offerError = offerError {
                        print("⚠️ [loadReceivedOffers] Offer 가져오기 실패: \(offerError.localizedDescription)")
                        group.leave()
                        return
                    }
                    
                    for doc in offerSnapshot!.documents {
                        if let tradeOffer = try? doc.data(as: TradeOffer.self) {
                            allOffers.append(tradeOffer)
                        } else {
                            print("❌ [loadReceivedOffers] Offer 데이터 디코딩 실패 (tradeId: \(tradeId), offerId: \(doc.documentID))")
                        }
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.offers = allOffers
                print("✅ 받은 트레이드 요청 불러오기 완료: \(self.offers.count)개")
                
                self.cacheProposerUsers() // ✅ 받은 오퍼 처리 후, 제안자 정보 캐싱 실행
            }
        }
    }
    
    /// ✅ 제안자의 유저 정보 캐싱 (캐시 + Firestore)
    private func cacheProposerUsers() {
        let proposerIds = Set(offers.map { $0.proposerId })
        
        for proposerId in proposerIds {
            if userMap[proposerId] != nil { continue } // ✅ 이미 있으면 생략
            
            UserService.shared.fetchUserById(proposerId) { [weak self] user in
                guard let self = self, let user = user else { return }
                
                DispatchQueue.main.async {
                    self.userMap[proposerId] = user // ✅ `userMap` 즉시 반영
                    print("✅ [cacheProposerUsers] 제안자 정보 캐싱 완료: \(user.nickname)")
                }
            }
        }
    }
}
