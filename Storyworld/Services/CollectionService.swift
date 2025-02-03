//
//  CollectionService.swift
//  Storyworld
//
//  Created by peter on 1/21/25.
//

import Foundation
import FirebaseFirestore // ✅ Firestore 사용을 위한 import 추가!
import FirebaseAuth
import FirebaseFunctions

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
    
    private let functions = Functions.functions()
    
    init() {
        userService.initializeUserIfNeeded()
    }
    
    func fetchUncollectedVideos(for genre: VideoGenre, rarity: VideoRarity, completion: @escaping (Result<[Video], Error>) -> Void) {
        guard UserService.shared.user != nil else {
            completion(.failure(NSError(domain: "User not found", code: 401, userInfo: nil)))
            return
        }
        
        // ✅ UserDefaults에서 수집된 영상 로드
        let collectedVideoIds = UserDefaults.standard.loadCollectedVideos().map { $0.video.videoId }
        
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
    
    // 수집된 모든 영상 즉시 반환
    func fetchAllVideos() -> [CollectedVideo] {
        let videos = UserDefaults.standard.loadCollectedVideos()
        print("🔍 UserDefaults에서 모든 영상 반환, 개수: \(videos.count)")
        return videos
    }
    
    // MARK: - 새 영상 수집 (보상 포함)
    func saveCollectedVideo(_ video: Video) async {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저가 없습니다.")
            return
        }
        
        // 1) UserDefaults에서 기존 수집 영상 가져오기
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        if collectedVideos.contains(where: { $0.video.videoId == video.videoId }) {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
            return
        }
        
        // 2) 새로운 CollectedVideo 객체 생성
        let newCollectedVideo = CollectedVideo(
            id: video.videoId,
            video: video,
            collectedDate: Date(),
            tradeStatus: .available,
            isFavorite: false,
            ownerId: uid
        )
        
        // 3) UserDefaults에 즉시 저장(오프라인 데이터)
        collectedVideos.append(newCollectedVideo)
        UserDefaults.standard.saveCollectedVideos(collectedVideos)
        
        // 4) Cloud Function 호출 (addCollectedVideo)
        let requestData: [String: Any] = [
            "videoId": video.videoId,
            "title": video.title,
            "rarity": video.rarity.rawValue,
            "genre": video.genre.rawValue
            // ownerId는 굳이 보낼 필요 없고, 서버에서 request.auth?.uid 이용 가능
        ]
        
        do {
            let _ = try await functions.httpsCallable("addCollectedVideo").call(requestData)
            print("🔥 [CF] Firestore에 영상 저장 성공: \(video.title)")
        } catch {
            print("❌ [CF] Firestore 저장 오류: \(error.localizedDescription)")
        }
        
        // 5) 보상 지급 (Swift 쪽 로직 유지)
        self.userService.rewardUser(for: video)
        
        print("✅ 영상 수집 완료 (보상 포함): \(video.title)")
    }
    
    // MARK: - 새 영상 수집 (보상 없음)
    func saveCollectedVideoWithoutReward(_ video: Video, amount: Int) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("❌ 현재 로그인된 유저가 없습니다.")
            return
        }
        
        // 1) UserDefaults에서 기존 수집 영상
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        if collectedVideos.contains(where: { $0.video.videoId == video.videoId }) {
            print("⚠️ 이미 존재하는 영상: \(video.videoId)")
            return
        }
        
        // 2) 새로운 CollectedVideo 객체
        let newCollectedVideo = CollectedVideo(
            id: video.videoId,
            video: video,
            collectedDate: Date(),
            tradeStatus: .available,
            isFavorite: false,
            ownerId: uid
        )
        
        // 3) 로컬 저장
        collectedVideos.append(newCollectedVideo)
        UserDefaults.standard.saveCollectedVideos(collectedVideos)
        
        // 4) Cloud Function 호출 (addCollectedVideoWithoutReward)
        let requestData: [String: Any] = [
            "videoId": video.videoId,
            "title": video.title,
            "rarity": video.rarity.rawValue,
            "genre": video.genre.rawValue
        ]
        
        Task {
            do {
                let _ = try await functions.httpsCallable("addCollectedVideoWithoutReward").call(requestData)
                print("🔥 [CF] Firestore에 영상 저장 완료 (보상X): \(video.title)")
            } catch {
                print("❌ [CF] Firestore 저장 오류: \(error.localizedDescription)")
            }
        }
        
        // 5) 경험치 지급 (코인 보상 제외)
        self.userService.rewardUserWithoutCoins(for: video, amount: amount)
        
        print("✅ 영상이 수집되었습니다 (코인 보상 없음): \(video.title)")
    }
    
    
    // MARK: - Firestore → UserDefaults 동기화 (읽기)
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
            
            UserDefaults.standard.saveCollectedVideos(videos)
            print("✅ Firestore -> UserDefaults 동기화 완료 (총 \(videos.count)개)")
        } catch {
            print("❌ 동기화 실패: \(error.localizedDescription)")
        }
    }
}
