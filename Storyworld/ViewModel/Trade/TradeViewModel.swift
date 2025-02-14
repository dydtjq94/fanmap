//
//  TradeViewModel.swift
//  Storyworld
//
//  Created by peter on 2/8/25.
//

import Foundation

class TradeViewModel: ObservableObject {
    
    @Published var trades: [Trade] = [] // 트레이드 리스트
    @Published var userMap: [String: User] = [:] // OwnerId별 유저 정보 맵핑
    
    // 트레이드 로딩 및 유저 정보 맵핑
    func loadTrades() {
        TradeService.shared.loadTrades { result in
            switch result {
            case .success(let loadedTrades):
                self.trades = loadedTrades
                self.groupTradesByOwner()
            case .failure(let error):
                print("❌ 트레이드 로딩 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // OwnerId별로 트레이드 그룹화
    private func groupTradesByOwner() {
        let grouped = Dictionary(grouping: trades, by: { $0.ownerId })
        
        // 모든 트레이드 소유자에 대해 사용자 정보 불러오기
        for (ownerId, _) in grouped {
            // ownerId에 해당하는 유저 정보를 UserService에서 가져오기
            fetchUserById(ownerId: ownerId)
        }
    }

    // OwnerId에 해당하는 사용자 정보 로드
    private func fetchUserById(ownerId: String) {
        UserService.shared.fetchUserById(ownerId) { user in
            if let user = user {
                self.userMap[ownerId] = user
            } else {
                print("❌ 사용자 정보 로드 실패: \(ownerId)")
            }
        }
    }
}
