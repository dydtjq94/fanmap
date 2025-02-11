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
        
        // 3. 트레이드 등록
        TradeService.shared.createTrade(for: newCollectedVideo) { success in
            if success {
                print("✅ 트레이드 등록 완료! \(video.title)")
            } else {
                print("❌ 트레이드 등록 실패...")
            }
        }
        
        // ✅ 3. 보상 지급
        self.userService.rewardUser(for: video)
        
        print("✅ 영상이 수집되었습니다: \(video.title)")
    }
    
    func saveCollectedVideoWithoutReward(_ video: Video, amount: Int) {
        guard let currentUser = userService.user else { return }
        
        let amount: Int = amount
        
        // ✅ UserDefaults에서 수집된 영상 로드
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        
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
        
        // 3. 트레이드 등록
        TradeService.shared.createTrade(for: newCollectedVideo) { success in
            if success {
                print("✅ 트레이드 등록 완료! \(video.title)")
            } else {
                print("❌ 트레이드 등록 실패...")
            }
        }
        
        // ✅ 3. 경험치 지급 (코인 보상 제외)
        self.userService.rewardUserWithoutCoins(for: video, amount: amount)
        
        print("✅ 영상이 수집되었습니다 (코인 보상 없음): \(video.title)")
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
    
    func deleteCollectedVideo(_ video: Video, completion: @escaping (Bool) -> Void) {
        guard let currentUser = userService.user else {
            print("❌ 유저 정보 없음")
            completion(false)
            return
        }
        
        // 1) UserDefaults에서 제거
        var collectedVideos = UserDefaults.standard.loadCollectedVideos()
        let beforeCount = collectedVideos.count
        collectedVideos.removeAll { $0.video.videoId == video.videoId }
        UserDefaults.standard.saveCollectedVideos(collectedVideos)
        let afterCount = collectedVideos.count
        
        if beforeCount == afterCount {
            print("⚠️ 삭제 대상이 없습니다 (UserDefaults에 해당 영상이 없음).")
        } else {
            print("✅ UserDefaults에서 영상(\(video.title)) 제거 완료")
        }
        
        // 2) Firestore에서 제거
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.id)
        let collectedVideosRef = userRef.collection("collectedVideos").document(video.videoId)
        
        Task {
            do {
                // 문서가 있을 경우 삭제, 없으면 에러 없이 그냥 진행
                try await collectedVideosRef.delete()
                print("✅ Firestore collectedVideos 문서 삭제 완료 (\(video.title))")
                
                // 성공 처리
                completion(true)
            } catch {
                print("❌ Firestore 영상 삭제 오류: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    func sellCollectedVideo(_ video: Video, coinAmount: Int, completion: @escaping (Bool) -> Void) {
        // 1) 먼저 영상 삭제(컬렉션) - 단순 로직
        self.deleteCollectedVideo(video) { deleteSuccess in
            if !deleteSuccess {
                print("❌ sellCollectedVideo - 영상 삭제 실패")
                completion(false)
                return
            }
            
            // 2) Trade 문서도 삭제 (등록되어 있다면)
            TradeService.shared.deleteTradeIfExists(
                ownerId: self.userService.user?.id ?? "",
                videoId: video.videoId
            ) { tradeDeleted in
                if !tradeDeleted {
                    print("❌ Trade 삭제 오류 발생")
                    completion(false)
                    return
                }
                
                // 3) 코인 지급
                self.userService.addCoins(amount: coinAmount)
                print("✅ \(coinAmount) 코인 지급 완료!")
                completion(true)
            }
        }
    }
}
