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

    /// ✅ 현재 사용자의 트레이드 목록 불러오기 (등록된 상태만)
    func loadUserTrades(status: TradeStatus) {
        guard let userId = userService.user?.id else { return }

        tradeService.fetchUserTrades(userId: userId, status: status) { [weak self] trades in
            DispatchQueue.main.async {
                self?.trades = trades
                print("✅ [ManageTradingViewModel] \(status.rawValue) 상태 트레이드 불러오기 완료: \(trades.count)개")
            }
        }
    }
    
    /// ✅ 내 컬렉션 불러오기
    func loadMyCollection() {
        DispatchQueue.main.async {
            self.collectedVideos = self.collectionService.fetchAllVideos()
            print("✅ [ManageTradingViewModel] 내 컬렉션 불러오기 완료: \(self.collectedVideos.count)개")
        }
    }

    /// ✅ 트레이드 등록
    func registerTrade(video: CollectedVideo) {
        tradeService.createTrade(for: video) { success in
            if success {
                DispatchQueue.main.async {
                    self.trades.append(Trade(id: UUID().uuidString, video: video.video, ownerId: video.ownerId, tradeStatus: .available, createdDate: Date()))
                    print("✅ [ManageTradingViewModel] 트레이드 등록 완료!")
                }
            }
        }
    }
    
    /// ✅ 트레이드 취소 (UUID 기반 `tradeId` 사용)
    func cancelTrade(trade: Trade) {
        tradeService.deleteTradeIfExists(ownerId: trade.ownerId, tradeId: trade.id) { success in
            if success {
                DispatchQueue.main.async {
                    self.trades.removeAll { $0.id == trade.id } // 🔥 리스트에서 즉시 제거
                    print("✅ [cancelTrade] 트레이드 취소 완료: \(trade.id)")
                }
            } else {
                print("❌ [cancelTrade] 트레이드 취소 실패: \(trade.id)")
            }
        }
    }

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
}
