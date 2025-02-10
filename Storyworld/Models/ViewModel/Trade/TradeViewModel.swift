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
    @Published var listings: [MarketListing] = []
    
    func loadAvailableListings() async {
        do {
            let result = try await TradeService.shared.fetchAvailableListings()
            self.listings = result
        } catch {
            print("❌ 거래 목록 불러오기 실패: \(error.localizedDescription)")
        }
    }
    
    // 필요 시, 실시간 리스너 or 상태 업데이트를 구현할 수도 있음
}
