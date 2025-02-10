//
//  CollectionService.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import Foundation
import FirebaseFirestore // ✅ Firestore 사용을 위한 import 추가!
import FirebaseAuth

extension VideoChannel {
    static func fromString(_ rawValue: String) -> VideoChannel {
        return VideoChannel(rawValue: rawValue) ?? .chimchakMan // 기본값 설정
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
    
    func fetchRandomVideoByGenre(genre: VideoGenre, rarity: VideoRarity, completion: @escaping (Result<Video, Error>) -> Void) {
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
                // 서버에서 받아온 원본 Video 객체
                var video = try decoder.decode(Video.self, from: data)
                
                // 🔥 rarity 값 덮어쓰기
                video.rarity = rarity
                
                completion(.success(video))
                print("🚀 서버에서 가져온 영상: \(video)")
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    
    func fetchRandomVideoByChannel(channel: VideoChannel, rarity: VideoRarity, completion: @escaping (Result<Video, Error>) -> Void) {
        let functionURL = "https://getrandomvideobychannel-bgfikxjrua-uc.a.run.app"
        
        guard let url = URL(string: "\(functionURL)?channel=\(channel.rawValue)") else {
            print("Invalid URL")
            return
        }
        
        print("✅ 보낸 채널 ID: \(channel.rawValue)")
        
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
                var video = try decoder.decode(Video.self, from: data)
                
                video.rarity = rarity
                
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
        let videos = UserDefaults.standard.loadCollectedVideos()
        print("🔍 UserDefaults에서 모든 영상 반환, 개수: \(videos.count)")
        return videos
    }
    
    // 새 영상 추가 및 저장
    func saveCollectedVideo(_ video: Video) async {
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        
        if !collectedVideos.contains(where: { $0.video.videoId == video.videoId }) {
            let newCollectedVideo = CollectedVideo(
                id: video.videoId,
                video: video,
                collectedDate: Date(),
                tradeStatus: .available,
                isFavorite: false,
                ownerId: Auth.auth().currentUser?.uid ?? "unknown"
            )
            
            // ✅ 1. UserDefaults 업데이트
            collectedVideos.append(newCollectedVideo)
            UserDefaults.standard.saveCollectedVideos(collectedVideos)
            
            // ✅ 2. Firestore에 저장 (서브컬렉션)
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(newCollectedVideo.ownerId)
            let collectedVideosRef = userRef.collection("collectedVideos").document(video.videoId)
            
            do {
                try collectedVideosRef.setData(from: newCollectedVideo)
                print("🔥 Firestore에 영상 저장 완료: \(video.title)")
            } catch {
                print("❌ Firestore 저장 오류: \(error.localizedDescription)")
            }
            
            // ✅ 3. 보상 지급
            self.userService.rewardUser(for: video)
            
            // 4. (중요) -> TradeService를 통해 마켓에 등록
            Task {
                do {
                    try await TradeService.shared.createMarketListing(from: newCollectedVideo)
                    print("✅ 마켓 등록")
                } catch {
                    print("❌ 마켓 등록 오류: \(error.localizedDescription)")
                }
            }
            
            print("✅ 영상이 수집되었습니다: \(video.title)")
        } else {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
        }
    }
    
    func saveCollectedVideoWithoutReward(_ video: Video, amount: Int) {
        guard let currentUser = userService.user else { return }
        
        let amount: Int = amount
        
        // ✅ UserDefaults에서 수집된 영상 로드
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        
        if !collectedVideos.contains(where: { $0.video.videoId == video.videoId }) {
            let newCollectedVideo = CollectedVideo(
                id: video.videoId, // ✅ Firestore 문서 ID와 일치
                video: video,
                collectedDate: Date(),
                tradeStatus: .available, // ✅ 거래 가능 상태 기본값 설정
                isFavorite: false,
                ownerId: currentUser.id // ✅ 유저 ID 사용
            )
            
            // ✅ 1. UserDefaults 업데이트
            collectedVideos.append(newCollectedVideo)
            UserDefaults.standard.saveCollectedVideos(collectedVideos)
            
            // ✅ 2. Firestore에 저장 (서브컬렉션)
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(currentUser.id)
            let collectedVideosRef = userRef.collection("collectedVideos").document(video.videoId)
            
            Task {
                do {
                    try collectedVideosRef.setData(from: newCollectedVideo) // 🔥 Firestore에 저장
                    print("🔥 Firestore에 영상 저장 완료: \(video.title)")
                } catch {
                    print("❌ Firestore 저장 오류: \(error.localizedDescription)")
                }
            }
            
            // ✅ 3. 경험치 지급 (코인 보상 제외)
            self.userService.rewardUserWithoutCoins(for: video, amount: amount)
            
            print("✅ 영상이 수집되었습니다 (코인 보상 없음): \(video.title)")
        } else {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
        }
    }
    
    
    func syncCollectedVideosWithFirestore() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        do {
            let snapshot = try await userRef.collection("collectedVideos").getDocuments()
            let videos = snapshot.documents.compactMap { try? $0.data(as: CollectedVideo.self) }
            
            // ✅ UserDefaults에 저장
            UserDefaults.standard.saveCollectedVideos(videos)
            print("✅ Firestore에서 collectedVideos 불러와서 UserDefaults에 저장 완료! (총 \(videos.count)개)")
        } catch {
            print("❌ Firestore에서 collectedVideos 불러오기 실패: \(error.localizedDescription)")
        }
    }
    
    func sellCollectedVideo(_ video: Video, coinAmount: Int, completion: @escaping (Bool) -> Void) {
        guard let currentUser = userService.user else {
            print("❌ 유저 정보 없음")
            completion(false)
            return
        }
        
        // ✅ 1. UserDefaults에서 영상 삭제
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        collectedVideos.removeAll { $0.video.videoId == video.videoId }
        UserDefaults.standard.saveCollectedVideos(collectedVideos)
        
        // ✅ 2. Firestore에서 영상 삭제
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.id)
        let collectedVideosRef = userRef.collection("collectedVideos").document(video.videoId)
        
        Task {
            do {
                try await collectedVideosRef.delete()
                print("🔥 Firestore에서 영상 삭제 완료: \(video.title)")
            } catch {
                print("❌ Firestore 영상 삭제 오류: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // ✅ 3. 코인 지급 (이제 외부에서 전달받은 `coinAmount` 사용)
            userService.addCoins(amount: coinAmount)
            print("✅ \(coinAmount) 코인 지급 완료!")
            
            completion(true)
        }
    }
    
}
