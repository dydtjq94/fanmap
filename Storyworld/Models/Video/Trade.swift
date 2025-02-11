//
//  Trade.swift
//  Storyworld
//
//  Created by peter on 2/8/25.
//

import Foundation
import FirebaseFirestore

struct Trade: Codable, Identifiable {
    var id: String     
    let video: Video                  // 전체 Video 구조체
    let ownerId: String               // 판매자(소유자) ID
    var tradeStatus: TradeStatus      // 거래 상태
    let createdDate: Date             // 생성 시각
}
