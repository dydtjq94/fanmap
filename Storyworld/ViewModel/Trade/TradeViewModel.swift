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
        for (ownerId, tradesForOwner) in grouped {
            // 예시로 유저 정보를 가져오는 부분. 필요 시, `UserService`에서 유저 정보 로드하는 로직 추가 가능
            if let user = UserService.shared.user { // 예시로 하나의 유저 정보를 사용
                userMap[ownerId] = user
            }
        }
    }
}
