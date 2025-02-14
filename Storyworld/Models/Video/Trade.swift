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
    let video: Video            // 전체 Video 구조체
    let ownerId: String               // 판매자(소유자) ID
    var tradeStatus: TradeStatus      // 거래 상태
    let createdDate: Date             // 생성 시각
}

enum TradeStatus: String, Codable {
    case available = "available"
    case pending = "pending"
    case done = "done"
}

struct TradeOffer: Identifiable, Codable {
    var id: String // ✅ Firestore 문서 ID 자동 매핑
    var tradeOwnerId: String // ✅ 트레이드 소유자 ID
    var proposerId: String // ✅ 제안을 보낸 유저 ID
    var tradeId: String // ✅ 트레이드 정보 (전체 Trade 객체 저장)
    var offeredVideos: [Video] // ✅ 교환할 Video 목록 (전체 Video 객체 저장)
    var status: String // ✅ 거래 상태 ("pending", "accepted", "rejected")
    var createdDate: Timestamp // ✅ 생성 시각 추가 (Firestore Timestamp)
}
