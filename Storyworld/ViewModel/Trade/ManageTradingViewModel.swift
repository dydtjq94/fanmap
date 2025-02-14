//
//  ManageTradingViewModel.swift
//  Storyworld
//
//  Created by peter on 2/12/25.
//

import SwiftUI
import FirebaseFirestore

class ManageTradingViewModel: ObservableObject {
    @Published var trades: [Trade] = []
    @Published var collectedVideos: [CollectedVideo] = []
    @Published var tradeMemo: String = ""

    private let tradeService = TradeService.shared
    private let userService = UserService.shared
    private let collectionService = CollectionService.shared

    /// ✅ 트레이드 메모 불러오기 (UserDefaults + Firestore)
    func fetchTradeMemo() -> String {
        return userService.user?.tradeMemo ?? ""
    }

    /// ✅ 트레이드 메모 업데이트 (UserDefaults + Firestore)
    func updateTradeMemo(memo: String) {
        guard var user = userService.user else { return }
        user.tradeMemo = memo
        userService.saveUser(user)
        print("✅ [ManageTradingViewModel] 트레이드 메모 업데이트 완료!")
    }
    
    // 내 트레이드 로드 메서드
    func loadUserTrades() {
        // 트레이드 데이터를 로드하는 로직
        // 예시로 Firestore에서 트레이드를 가져온다고 가정
        let db = Firestore.firestore()
        db.collection("trades")
            .whereField("ownerId", isEqualTo: UserService.shared.user?.id ?? "")
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ 트레이드 로드 실패: \(error.localizedDescription)")
                    return
                }
                
                self.trades = snapshot?.documents.compactMap { document in
                    try? document.data(as: Trade.self)
                } ?? []
            }
    }
    
    // ✅ 트레이드 등록 (Firestore와 UserDefaults에 저장)
    func registerSelectedTrades(videos: [CollectedVideo], memo: String) {
        // 여러 video에 대해 순차적으로 트레이드 등록
        for video in videos {
            // 트레이드 객체 생성
            var trade = Trade(
                id: UUID().uuidString, // 새 트레이드 ID
                video: video.video, // 첫 번째 선택된 영상을 트레이드 영상으로 사용
                ownerId: UserService.shared.user?.id ?? "unknown", // 사용자 ID
                tradeStatus: .available, // 초기 상태는 'available'
                createdDate: Date() // 생성일
            )
            
            // Firestore에 트레이드 저장
            tradeService.createTrade(video: video.video) { result in
                switch result {
                case .success(let tradeId):
                    print("✅ 트레이드 등록 성공, 트레이드 ID: \(tradeId)")
                    
                    // UserDefaults에서 등록한 영상 삭제
                    var collectedVideos = UserDefaults.standard.loadCollectedVideos()
                    collectedVideos.removeAll { $0.id == video.id }
                    UserDefaults.standard.saveCollectedVideos(collectedVideos)
                    
                    // 등록된 영상들을 트레이드 목록에서 즉시 제거
                    DispatchQueue.main.async {
                        self.trades.append(trade)
                        print("✅ 트레이드 목록에 추가 완료")
                    }
                    
                case .failure(let error):
                    print("❌ 트레이드 등록 실패: \(error.localizedDescription)")
                }
            }
        }
    }

    /// ✅ 트레이드 취소 (UI에서 즉시 반영)
    func cancelTrade(trade: Trade) {
        tradeService.cancelTrade(ownerId: trade.ownerId, tradeId: trade.id) { success in
            if success {
                DispatchQueue.main.async {
                    self.trades.removeAll { $0.id == trade.id }
                    print("✅ [cancelTrade] 트레이드 취소 완료: \(trade.id)")
                }
            } else {
                print("❌ [cancelTrade] 트레이드 취소 실패: \(trade.id)")
            }
        }
    }
}
