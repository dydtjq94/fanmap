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
    @Published var trades: [Trade] = []
    @Published var userMap: [String: User] = [:] // ownerId -> User
    
    private let tradeService = TradeService.shared
    
    func loadTrades() {
        tradeService.fetchAllTrades { [weak self] fetchedTrades in
            guard let self = self else { return }
            
            Task { @MainActor in
                self.trades = fetchedTrades
                print("✅ 트레이드 목록 불러오기 완료: \(fetchedTrades.count)개")
            }
            
            // 오너별 유저 정보 가져오기
            let ownerIds = Set(fetchedTrades.map { $0.ownerId })
            for ownerId in ownerIds {
                UserService.shared.fetchUserById(ownerId) { user in
                    guard let user = user else { return }
                    Task { @MainActor in
                        self.userMap[ownerId] = user
                    }
                }
            }
        }
    }
}
