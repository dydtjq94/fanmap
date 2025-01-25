//
//  CollectionService.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import Foundation

class CollectionService {
    static let shared = CollectionService()
    private let userService = UserService.shared
    
    init() {
        userService.initializeUserIfNeeded()
    }
    
    func fetchUncollectedVideos(for genre: VideoGenre, rarity: VideoRarity, completion: @escaping (Result<[Video], Error>) -> Void) {
        guard let currentUser = UserService.shared.user else {
            completion(.failure(NSError(domain: "User not found", code: 401, userInfo: nil)))
            return
        }

        let collectedVideoIds = currentUser.collectedVideos.map { $0.video.videoId }

        let filteredVideos = VideoDummyData.sampleVideos.filter { video in
            video.genre == genre &&
            video.rarity == rarity &&
            !collectedVideoIds.contains(video.videoId)
        }

        DispatchQueue.main.async {
            if filteredVideos.isEmpty {
                completion(.failure(NSError(domain: "No videos found", code: 404, userInfo: nil)))
            } else {
                completion(.success(filteredVideos))
            }
        }
    }
    
    // 수집된 모든 영상 즉시 반환
    func fetchAllVideos() -> [CollectedVideo] {
        guard let user = userService.user else { return [] }
        print("🔍 모든 영상 반환, 개수: \(user.collectedVideos.count)")
        return user.collectedVideos
    }
    
    // 새 영상 추가 및 저장
    func saveCollectedVideo(_ video: Video) {
        guard var currentUser = userService.user else { return }
        
        if !currentUser.collectedVideos.contains(where: { $0.video.videoId == video.videoId }) {
            let newCollectedVideo = CollectedVideo(
                video: video,
                collectedDate: Date(),
                playlistIds: [],
                isFavorite: false,
                userTags: nil,
                ownerId: currentUser.nickname
            )
            
            // 수집 목록 추가
            currentUser.collectedVideos.append(newCollectedVideo)
            
            // 업데이트된 user 객체를 저장
            userService.user = currentUser
            
            // 보상 지급
            self.userService.rewardUser(for: video)
            
            print("✅ 영상이 수집되었습니다: \(video.title)")
        } else {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
        }
    }
}
