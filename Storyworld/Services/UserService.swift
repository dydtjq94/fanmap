//
//  UserService.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation
import FirebaseAuth
import FirebaseStorage
import FirebaseFirestore
import SwiftUI  // UIImage, ObservableObject 위해 SwiftUI 임포트

class UserService: ObservableObject {
    static let shared = UserService()
    @Published var user: User?
    
    // ✅ 다른 유저들 캐시: [userId: (User, fetchedAt)]
    private var cachedUsers: [String: (user: User, fetchedAt: Date)] = [:]
    private let timeToLive: TimeInterval = 24 * 60 * 60 // 24시간
    
    // MARK: - 다른 유저 정보 가져오기 (24h TTL)
    /// TradeTab 등에서 'ownerId'가 필요할 때 호출
    func fetchUserById(_ userId: String, completion: @escaping (User?) -> Void) {
        // 1) 캐시에 있으면 & 유효기간 이내라면 반환
        if let cached = cachedUsers[userId] {
            let elapsed = Date().timeIntervalSince(cached.fetchedAt)
            if elapsed < timeToLive {
                completion(cached.user)
                return
            } else {
                // 만료
                cachedUsers.removeValue(forKey: userId)
            }
        }
        
        // 2) Firestore에서 문서 가져오기
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.getDocument { snapshot, error in
            if let error = error {
                print("❌ fetchUserById 에러: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("⚠️ 해당 user 문서 없음 (userId=\(userId))")
                completion(nil)
                return
            }
            
            do {
                let fetchedUser = try snapshot.data(as: User.self)
                // 3) 캐시에 저장 (fetchedAt = now)
                self.cachedUsers[userId] = (fetchedUser, Date())
                completion(fetchedUser)
            } catch {
                print("❌ 디코딩 오류: \(error)")
                completion(nil)
            }
        }
    }
    
    // 만약 앱 재시작 시 캐시를 날리려면
    func clearOtherUsersCache() {
        cachedUsers.removeAll()
    }
    
    private let userDefaultsKey = "currentUser"
    
    // MARK: - 앱 시작 시 UserDefaults → (필요 시) Firestore 동기화
    func initializeUserIfNeeded() {
        DispatchQueue.main.async {
            if let savedUser = self.loadUserFromLocal() {
                print("✅ 기존 유저 로드: \(savedUser.nickname)")
                self.user = savedUser
                
                // 필요 시 Firestore에서 최신 정보 다시 가져오기
                Task {
                    await self.fetchUserFromFirestore(userID: savedUser.id)
                }
            } else {
                print("⏩ 기존 유저 없음 (StartView 등에서 새 유저 생성 처리)")
                self.user = nil
            }
        }
    }
    
    // MARK: - Firestore에서 유저 정보 가져오기(Dictionary 방식)
    func fetchUserFromFirestore(userID: String) async {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userID)
        
        do {
            let snapshot = try await userRef.getDocument()
            guard let data = snapshot.data() else {
                print("❌ Firestore 문서 없음 or 데이터 없음")
                return
            }
            
            // Firestore의 Timestamp를 Date로 변환
            let tradeUpdatedTimestamp = data["tradeUpdated"] as? Timestamp
            let tradeUpdatedDate = tradeUpdatedTimestamp?.dateValue()
            
            let tradeMemoStr = data["tradeMemo"] as? String // 없는 경우 nil
            
            // Dictionary → User
            let fetchedUser = User(
                id: data["id"] as? String ?? "",
                email: data["email"] as? String ?? "",
                nickname: data["nickname"] as? String ?? "",
                profileImageURL: data["profileImageURL"] as? String,
                bio: data["bio"] as? String,
                experience: data["experience"] as? Int ?? 0,
                balance: data["balance"] as? Int ?? 0,
                gems: data["gems"] as? Int ?? 0,
                tradeUpdated: tradeUpdatedDate,
                tradeMemo: tradeMemoStr
            )
            
            print("✅ Firestore에서 유저 정보 가져옴: \(fetchedUser.nickname)")
            
            // 가져온 정보 로컬에 반영
            self.saveUserToLocal(fetchedUser)
            
        } catch {
            print("❌ Firestore에서 유저 정보 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 프로필 이미지 업로드
    func uploadProfileImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let user = self.user else { return }
        
        let optimizedImage = image.resized(toWidth: 200)
        guard let imageData = optimizedImage.jpegData(compressionQuality: 0.5) else { return }
        
        let storageRef = Storage.storage().reference()
        let profileImageRef = storageRef.child("profile_images/\(user.id).jpg")
        
        profileImageRef.putData(imageData, metadata: nil) { metadata, error in
            if let error = error {
                print("❌ 이미지 업로드 실패: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            profileImageRef.downloadURL { url, error in
                if let error = error {
                    print("❌ URL 가져오기 실패: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                completion(url) // -> updateProfileImageURL에서 Firestore에 반영
            }
        }
    }
    
    // MARK: - Firestore에 프로필 이미지 URL 저장
    func updateProfileImageURL(imageURL: URL) {
        guard var user = self.user else { return }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        userRef.updateData(["profileImageURL": imageURL.absoluteString]) { error in
            if let error = error {
                print("❌ Firestore 업데이트 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore에 프로필 이미지 URL 저장 완료: \(imageURL)")
                
                DispatchQueue.main.async {
                    user.profileImageURL = imageURL.absoluteString
                    self.user = user
                    self.saveUserToLocal(user) // -> UserDefaults에 전체 User 저장
                    
                    // ✅ (원한다면) 로컬 파일에 저장된 이미지와 URL을 동기화하는 로직을 넣어도 됨
                }
            }
        }
    }
    
    // MARK: - 프로필 이미지 로딩 (서버에서 URL만 쓴다)
    func loadProfileImage(completion: @escaping (UIImage?) -> Void) {
        // 1) 로컬 파일 먼저 확인
        if let localImage = loadProfileImageLocally() {
            print("✅ 로컬 프로필 이미지 사용")
            completion(localImage)
            // 여기서 return하지 않고 "최신 버전"을 위해 서버 다운로드도 할 수 있음 (원한다면)
            return
        }
        
        // 2) 로컬에 없다면, Firestore에 있는 URL로 다운로드
        guard let user = self.user,
              let profileURLString = user.profileImageURL,
              let url = URL(string: profileURLString) else {
            completion(nil)
            return
        }
        
        print("🔍 로컬 파일이 없으므로 서버에서 다운로드 시도")
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    // 로컬 파일로도 저장
                    self.saveProfileImageLocally(image)
                    completion(image)
                }
            } else {
                print("❌ 프로필 이미지 서버 다운로드 실패: \(error?.localizedDescription ?? "")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    // ✅ URL에서 이미지 다운로드하는 함수
    private func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    completion(image)
                }
            } else {
                print("❌ 이미지 다운로드 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                completion(nil)
            }
        }.resume()
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// ✅ 로컬에 프로필 이미지를 "profileImage.jpg"로 저장
    func saveProfileImageLocally(_ image: UIImage) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("profileImage.jpg")
        // 원하는 만큼 압축 품질 조정
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                print("✅ 로컬에 프로필 이미지 저장 완료: \(fileURL.path)")
            } catch {
                print("❌ 프로필 이미지 로컬 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// ✅ 로컬에 저장된 프로필 이미지를 불러옴 (없으면 nil)
    func loadProfileImageLocally() -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("profileImage.jpg")
        
        // 파일이 존재하는지 확인
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("❌ 로컬 프로필 이미지 로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    // MARK: - UserDefaults 저장/로드 - (로컬 전용)
        func loadUserFromLocal() -> User? {
            if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
                do {
                    let decodedUser = try JSONDecoder().decode(User.self, from: data)
                    return decodedUser
                } catch {
                    print("Error decoding user: \(error)")
                    return nil
                }
            }
            return nil
        }
    
    func saveUserToLocal(_ user: User) {
           do {
               let encoded = try JSONEncoder().encode(user)
               UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
               // 메모리 상태도 업데이트
               DispatchQueue.main.async {
                   self.user = user
               }
               print("✅ User saved to UserDefaults.")
           } catch {
               print("Error encoding user: \(error)")
           }
       }
    
    // MARK: - Firestore 저장(Dictionary 방식) - (서버 전용)
        func saveUserToFirestore(_ user: User) async {
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(user.id)
            
            // User → Dictionary
            let userData: [String: Any] = [
                "id": user.id,
                "email": user.email,
                "nickname": user.nickname,
                "profileImageURL": user.profileImageURL ?? "",
                "bio": user.bio ?? "",
                "experience": user.experience,
                "balance": user.balance,
                "gems": user.gems,
                "tradeUpdated": user.tradeUpdated ?? Date(),
                "tradeMemo": user.tradeMemo ?? ""
            ]
            
            do {
                try await userRef.setData(userData)
                print("🔥 Firestore에 유저 정보 저장 성공: \(user.nickname)")
            } catch {
                print("❌ Firestore에 유저 정보 저장 실패: \(error.localizedDescription)")
            }
        }
    
    // MARK: - 로컬 + Firestore 동시 업데이트도 가능하게(옵션)
    /// 필요에 따라 Firestore까지 동기화하도록 flag 사용
    func saveUser(_ user: User, alsoSyncToFirestore: Bool = true) {
        // 1) 로컬 저장
        self.saveUserToLocal(user)
        
        // 2) Firestore 동기화 여부에 따라 저장
        if alsoSyncToFirestore {
            Task {
                await self.saveUserToFirestore(user)
            }
        }
    }
    
    // MARK: - 보상 로직 등
    func rewardUser(for video: Video) {
        guard var user = user else { return }
        
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        let coinReward = UserStatusManager.shared.getCoinReward(for: video.rarity)
        
        user.experience += experienceReward
        user.balance += coinReward
        
        // 📌 tradeUpdated = 현재 기기 시간을 기록 (Date())
        user.tradeUpdated = Date()
        
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치: +\(experienceReward), 코인: +\(coinReward), 새 레벨: \(newLevel)")
        
        self.saveUser(user)
    }
    
    func rewardUserWithoutCoins(for video: Video, amount: Int) {
        guard var user = user else { return }
        
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        user.experience += experienceReward
        user.balance -= amount
        
        // 📌 tradeUpdated = 현재 기기 시간을 기록 (Date())
        user.tradeUpdated = Date()
        
        if user.balance < 0 { user.balance = 0 }
        
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치: +\(experienceReward), 코인: -\(amount), 새 레벨: \(newLevel)")
        
        self.saveUser(user)
    }
    
    func canAffordCoins(amount: Int) -> Bool {
        guard let user = user else {
            print("❌ 사용자 정보 없음")
            return false
        }
        return user.balance >= amount
    }
    
    func addCoins(amount: Int) {
        guard var user = user else {
            print("❌ 사용자 정보 없음")
            return
        }
        
        user.balance += amount
        print("💰 \(amount) 코인 추가! 현재 잔액: \(user.balance)")
        
        self.saveUser(user) // ✅ UserDefaults & Firestore에 업데이트
    }
    
}
