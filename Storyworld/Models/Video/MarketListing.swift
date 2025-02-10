//
//  MarketListing.swift
//  Storyworld
//
//  Created by peter on 2/8/25.
//

import Foundation
import FirebaseFirestore

struct MarketListing: Codable, Identifiable, Equatable {
    @DocumentID var id: String?  // Firestore 문서 ID (자동 할당 가능)
    let video: Video
    let ownerId: String
    var tradeStatus: TradeStatus
    let createdDate: Date
    
    // Equatable 구현
    static func == (lhs: MarketListing, rhs: MarketListing) -> Bool {
        lhs.id == rhs.id
    }
}
