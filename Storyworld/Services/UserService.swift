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

class UserService: ObservableObject {
    static let shared = UserService()
    @Published var user: User?
    
    private let userDefaultsKey = "currentUser"
    
    // MARK: - 앱 시작 시 UserDefaults → (필요 시) Firestore 동기화
    func initializeUserIfNeeded() {
        DispatchQueue.main.async {
            if let savedUser = self.loadUser() {
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
            
            // Dictionary → User
            let fetchedUser = User(
                id: data["id"] as? String ?? "",
                email: data["email"] as? String ?? "",
                nickname: data["nickname"] as? String ?? "",
                profileImageURL: data["profileImageURL"] as? String,
                bio: data["bio"] as? String,
                experience: data["experience"] as? Int ?? 0,
                balance: data["balance"] as? Int ?? 0,
                gems: data["gems"] as? Int ?? 0
            )
            
            print("✅ Firestore에서 유저 정보 가져옴: \(fetchedUser.nickname)")
            
            // 가져온 정보 로컬에 반영
            self.saveUser(fetchedUser)
            
        } catch {
            print("❌ Firestore에서 유저 정보 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Firestore에 유저 정보 저장(Dictionary 방식)
    func syncUserToFirestore(_ user: User) async {
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
            "gems": user.gems
        ]
        
        do {
            try await userRef.setData(userData)
            print("🔥 Firestore에 유저 정보 저장 성공: \(user.nickname)")
        } catch {
            print("❌ Firestore에 유저 정보 저장 실패: \(error.localizedDescription)")
        }
    }
    
    private let profileImageCacheKey = "cachedProfileImageURL"
    
    // Firestore에서 프로필 이미지 URL 가져오기 (UserDefaults에 캐싱)
    func fetchProfileImageURLIfNeeded() async {
        guard let user = self.user else { return }
        
        // ✅ 1. UserDefaults에서 캐싱된 URL 확인
        if let cachedURL = UserDefaults.standard.string(forKey: profileImageCacheKey) {
            DispatchQueue.main.async { [weak self] in
                self?.user?.profileImageURL = cachedURL
            }
            print("✅ 캐싱된 프로필 이미지 URL 사용: \(cachedURL)")
            return
        }
        
        // ✅ 2. Firestore에서 가져오고 캐싱
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        do {
            let snapshot = try await userRef.getDocument()
            if let data = snapshot.data(), let profileURL = data["profileImageURL"] as? String {
                DispatchQueue.main.async {
                    self.user?.profileImageURL = profileURL
                    UserDefaults.standard.set(profileURL, forKey: self.profileImageCacheKey) // ✅ 캐싱
                }
                print("✅ Firestore에서 가져온 프로필 이미지 URL: \(profileURL)")
            }
        } catch {
            print("❌ Firestore에서 프로필 이미지 URL 가져오기 실패: \(error.localizedDescription)")
        }
    }
    
    // Firebase Storage에 프로필 이미지 업로드 (최적화 적용)
    func uploadProfileImage(_ image: UIImage, completion: @escaping (URL?) -> Void) {
        guard let user = self.user else { return }
        
        // ✅ 이미지 최적화 (압축 및 크기 조정)
        let optimizedImage = image.resized(toWidth: 300)
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
                
                completion(url)
            }
        }
    }
    
    // Firestore에 프로필 이미지 URL 저장 (업데이트 시 캐시도 갱신)
    func updateProfileImageURL(imageURL: URL) {
        guard var user = self.user else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(user.id)
        
        userRef.updateData(["profileImageURL": imageURL.absoluteString]) { error in
            if let error = error {
                print("❌ Firestore 업데이트 실패: \(error.localizedDescription)")
            } else {
                print("✅ Firestore에 프로필 이미지 URL 저장 완료: \(imageURL)")
                
                // ✅ Firestore 저장 후 캐싱도 업데이트
                DispatchQueue.main.async {
                    user.profileImageURL = imageURL.absoluteString
                    self.user = user
                    UserDefaults.standard.set(imageURL.absoluteString, forKey: self.profileImageCacheKey)
                    self.saveUser(user)
                }
            }
        }
    }
    
    // ✅ 범용적인 프로필 이미지 로딩 함수
    func loadProfileImage(completion: @escaping (UIImage?) -> Void) {
        guard let profileURL = user?.profileImageURL, let url = URL(string: profileURL) else {
            completion(nil)
            return
        }
        
        // ✅ 캐시된 이미지가 있다면 즉시 반환
        if let cachedImage = ImageCache.shared.get(forKey: profileURL) {
            print("✅ 캐싱된 프로필 이미지 로드")
            completion(cachedImage)
        } else {
            // ✅ 없으면 다운로드 후 캐싱
            downloadImage(from: url) { image in
                if let image = image {
                    ImageCache.shared.set(image, forKey: profileURL) // ✅ 로컬 캐싱
                }
                completion(image)
            }
        }
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
    
    
    // MARK: - UserDefaults에서 로드
    private func loadUser() -> User? {
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
    
    // MARK: - UserDefaults + Firestore 동기화
    func saveUser(_ user: User) {
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            DispatchQueue.main.async {
                self.user = user
            }
            print("✅ User saved to UserDefaults.")
            
            // Firestore에도 즉시 갱신
            Task {
                await syncUserToFirestore(user)
            }
        } catch {
            print("Error encoding user: \(error)")
        }
    }
    
    // MARK: - 보상 로직 등
    func rewardUser(for video: Video) {
        guard var user = user else { return }
        
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        let coinReward = UserStatusManager.shared.getCoinReward(for: video.rarity)
        
        user.experience += experienceReward
        user.balance += coinReward
        
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치: +\(experienceReward), 코인: +\(coinReward), 새 레벨: \(newLevel)")
        
        self.saveUser(user)
    }
    
    func rewardUserWithoutCoins(for video: Video, amount: Int) {
        guard var user = user else { return }
        
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        user.experience += experienceReward
        user.balance -= amount
        
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
