//
//  User.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation

struct User: Codable, Equatable {
    var id: UUID
    var nickname: String  // 닉네임
    var profileImageURL: String?  // 프로필 이미지 URL (옵션)
    var bio: String?  // 소개글
    var experience: Int  // 경험치
    var balance: Int  // 사용자 보유 금액
    var gems: Int  // 보석 개수
    var collectedVideos: [CollectedVideo]  // 수집한 영상 목록
    var playlists: [Playlist]  // 플레이리스트 전체 저장
}

