//
//  UserService.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation
import FirebaseAuth
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
   
}
