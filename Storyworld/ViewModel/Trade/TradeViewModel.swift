//
//  TradeViewModel.swift
//  Storyworld
//
//  Created by peter on 2/8/25.
//

import SwiftUI
import FirebaseFirestore

@MainActor
class TradeViewModel: ObservableObject {
    @Published var trades: [Trade] = [] // "available" 상태 트레이드 저장
    @Published var userMap: [String: User] = [:] // ownerId -> User (캐싱)

    private let tradeService = TradeService.shared
    private let userService = UserService.shared
    
    /// ✅ 최신 20명의 유저를 가져온 후, 해당 유저들의 "available" 상태의 트레이드 가져오기
    func loadRecentTrades() {
        userService.fetchRecentUsers { [weak self] users in
            guard let self = self else { return }

            if users.isEmpty {
                print("⚠️ [loadRecentTrades] 가져올 유저 없음")
                self.trades = []
                return
            }

            let ownerIds = users.map { $0.id }
            
            Task { @MainActor in
                for user in users {
                    self.userMap[user.id] = user // ✅ 가져온 유저 정보 캐싱 (12시간 유지)
                }
            }

            // ✅ 최신 유저들의 "available" 트레이드 가져오기
            tradeService.fetchAvailableTradesForUsers(users: users) { availableTrades in
                Task { @MainActor in
                    self.trades = availableTrades
                    print("✅ 최신 20명 유저의 'available' 상태 트레이드 불러오기 완료: \(self.trades.count)개")
                }

                // ✅ 오너별 유저 정보 캐싱 (Firestore 요청 최적화)
                self.cacheOwnerUsers(trades: availableTrades)
            }
        }
    }
    
    /// ✅ 오너별 유저 정보 캐싱 (Firestore 요청 최적화)
    private func cacheOwnerUsers(trades: [Trade]) {
        let ownerIds = Set(trades.map { $0.ownerId })
        
        print("🔍 [cacheOwnerUsers] 총 \(ownerIds.count)명의 유저 정보 캐싱 시도")

        for ownerId in ownerIds {
            // ✅ 캐시에서 유저 확인 후 있으면 Firestore 요청 생략
            userService.fetchUserById(ownerId) { [weak self] user in
                guard let self = self, let user = user else {
                    print("❌ [cacheOwnerUsers] Firestore에서 가져온 유저 없음 (userId=\(ownerId))")
                    return
                }
                Task { @MainActor in
                    self.userMap[ownerId] = user
                    print("✅ [cacheOwnerUsers] 오너 정보 캐싱 완료: \(user.nickname)")
                }
            }
        }
    }
}
