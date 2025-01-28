//
//  CollectionService.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import Foundation

extension VideoGenre {
    static func fromString(_ rawValue: String) -> VideoGenre {
        return VideoGenre(rawValue: rawValue) ?? .talk // 기본값 설정
    }
}

extension VideoRarity {
    static func fromString(_ rawValue: String) -> VideoRarity {
        return VideoRarity(rawValue: rawValue) ?? .silver // 기본값 설정
    }
}
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
    
    func fetchRandomVideoByGenre(genre: VideoGenre, completion: @escaping (Result<Video, Error>) -> Void) {
        let functionURL = "https://getrandomvideobygenre-bgfikxjrua-uc.a.run.app"
        
        guard let url = URL(string: "\(functionURL)?genre=\(genre.rawValue)") else {
            print("Invalid URL")
            return
        }

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let statusError = NSError(domain: "HTTPError", code: (response as? HTTPURLResponse)?.statusCode ?? 500, userInfo: nil)
                completion(.failure(statusError))
                return
            }

            guard let data = data else {
                let noDataError = NSError(domain: "DataError", code: -1, userInfo: nil)
                completion(.failure(noDataError))
                return
            }
            do {
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                decoder.dateDecodingStrategy = .formatted(formatter)
                let video = try decoder.decode(Video.self, from: data)
                completion(.success(video))
                print("🚀 서버에서 가져온 영상: \(video)")
            } catch {
                completion(.failure(error))
            }
        }

        task.resume()
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
    
    func saveCollectedVideoWithoutReward(_ video: Video, amount: Int) {
        guard var currentUser = userService.user else { return }
        
        let amount: Int = amount
        
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

            // 업데이트된 user 객체를 저장 (코인 보상 제외)
            userService.user = currentUser
            
            // 경험치만 지급 (코인 보상 제외)
            self.userService.rewardUserWithoutCoins(for: video, amount: amount)

            print("✅ 영상이 수집되었습니다 (코인 보상 없음): \(video.title)")
        } else {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
        }
    }
}
