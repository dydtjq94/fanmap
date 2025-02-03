//
//  UserService.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation
import FirebaseFunctions  // ✅ 추가
import FirebaseAuth       // ✅ uid 사용 시 필요

class UserService: ObservableObject {
    static let shared = UserService()
    @Published var user: User?
    
    private let userDefaultsKey = "currentUser"
    private let functions = Functions.functions() // ✅ 클라우드 함수 호출용
    
    func initializeUserIfNeeded() {
        DispatchQueue.main.async {
            if let savedUser = self.loadUser() {
                print("✅ 기존 유저 로드: \(savedUser.nickname)")
                self.user = savedUser
            } else {
                print("⏩ 기존 유저 없음 (새 유저 생성 X, StartView에서 처리)")
                self.user = nil
            }
        }
    }
    
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
    
    func saveUser(_ user: User) {
        do {
            // 1) 로컬 저장
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            
            DispatchQueue.main.async {
                self.user = user
                print("✅ User saved to UserDefaults.")
            }

            // 2) 서버 반영 (항상)
            Task {
                await updateUserOnServer(user)
            }
        } catch {
            print("Error encoding user: \(error)")
        }
    }
    
    // MARK: - 보상 (코인 + 경험치)
    func rewardUser(for video: Video) {
        guard var user = user else { return }
        
        // 1) 로컬 보상 처리
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        let coinReward = UserStatusManager.shared.getCoinReward(for: video.rarity)
        user.experience += experienceReward
        user.balance += coinReward
        
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치 \(experienceReward), 코인 \(coinReward), 새 레벨 \(newLevel)")
        
        // 2) 로컬 저장
        self.saveUser(user)
    }
    
    // MARK: - 보상 (경험치만, 코인 x)
    func rewardUserWithoutCoins(for video: Video, amount: Int) {
        guard var user = user else { return }
        
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        
        user.experience += experienceReward
        user.balance -= amount
        if user.balance < 0 { user.balance = 0 } // 혹시라도 음수 보호
        
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치 \(experienceReward), 코인 차감 \(amount), 새 레벨 \(newLevel)")
        
        self.saveUser(user)
    }
    
    func deductCoins(amount: Int) -> Bool {
        guard var user = user else {
            print("❌ 사용자 정보 없음")
            return false
        }
        
        if user.balance >= amount {
            user.balance -= amount
            if user.balance < 0 {
                user.balance = 0
            }
            
            // 로컬에 저장
            self.saveUser(user)
            
            return true
        } else {
            print("❌ 잔액 부족. 현재 잔액: \(user.balance)")
            return false
        }
    }
    
    // MARK: - [새로 추가] 서버에 업데이트 (Cloud Function: updateUserProfile)
    /// 서버 DB의 users/{uid} 문서에 로컬 User 정보(경험치, 코인, bio 등) 반영
    func updateUserOnServer(_ user: User) async {
        guard !user.id.isEmpty else {
            print("❌ updateUserOnServer: user.id가 비어있음.")
            return
        }
        
        // Firebase Functions 호출
        let requestData: [String: Any] = [
            "uid": user.id,
            "email": user.email,
            "nickname": user.nickname,
            "profileImageURL": user.profileImageURL ?? "",
            "bio": user.bio,
            "experience": user.experience,
            "balance": user.balance,
            "gems": user.gems
        ]
        
        do {
            let result = try await functions.httpsCallable("updateUserProfile").call(requestData)
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                print("✅ 서버에 유저 정보 업데이트 완료!")
            } else {
                print("❌ 서버 업데이트 응답값 이상함.")
            }
        } catch {
            print("❌ 서버 업데이트 오류: \(error.localizedDescription)")
        }
    }
}
