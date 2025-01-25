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
    let thumbnailURL: String
    let channelId: String // 채널 ID만 참조
    let publishDate: Date?
    let genre: VideoGenre
    let rarity: VideoRarity
}

// 사용자가 수집한 영상을 위한 별도 모델
struct CollectedVideo: Codable, Equatable, Hashable, Identifiable {
    var id: String { video.videoId }  // Identifiable 프로토콜 준수를 위해 videoId 사용
    let video: Video  // 원본 영상 참조
    let collectedDate: Date  // 수집 날짜
    var playlistIds: [UUID]  // 플레이리스트 ID 리스트
    let isFavorite: Bool  // 즐겨찾기 여부
    let userTags: [String]?  // 사용자가 추가한 태그 리스트
    let ownerId: String  // 소유자 ID (예: 사용자 고유 ID)

    func hash(into hasher: inout Hasher) {
        hasher.combine(video.videoId)
    }
}

// 플레이리스트 모델
struct Playlist: Codable, Equatable, Hashable, Identifiable {
    var id: UUID  // 고유 식별자
    var name: String  // 플레이리스트 이름
    var description: String?  // 설명
    var createdDate: Date  // 생성 날짜
    var videoIds: [String]  // 포함된 영상의 ID 목록
    var thumbnailURL: String?  // 클라우드 URL (사용자가 변경 시 업데이트)
    var defaultThumbnailName: String  // 기본 이미지 (내장 이미지 이름)
    let ownerId: String  // 소유자 ID
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
