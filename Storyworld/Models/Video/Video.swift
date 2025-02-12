//
//  Video.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation

struct Video: Codable, Equatable, Hashable {
    let videoId: String
    let title: String
    let description: String?
    let channelId: String // 채널 ID만 참조
    let publishDate: Date?
    var rarity: VideoRarity
}

struct CollectedVideo: Codable, Equatable, Hashable, Identifiable {
    var id: String  // Firestore 문서 ID (videoId 사용 X)
    let video: Video  // 원본 영상 정보
    let collectedDate: Date  // 수집 날짜
    var tradeStatus: TradeStatus  // ✅ 거래 상태 추가
    let isFavorite: Bool  // 즐겨찾기 여부
    let ownerId: String  // 소유자 ID

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// 플레이리스트 모델 (Firestore 문서 ID 사용)
struct Playlist: Codable, Equatable, Hashable, Identifiable {
    var id: String  // ✅ UUID → String 변경
    var name: String
    var description: String?
    var createdDate: Date
    var videoIds: [String]  // ✅ 누락된 videoIds 추가
    var thumbnailURL: String?
    var defaultThumbnailName: String
    let ownerId: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
