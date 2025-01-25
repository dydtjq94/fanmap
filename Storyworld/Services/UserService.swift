//
//  UserService.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation

class UserService: ObservableObject {
    static let shared = UserService()
    @Published var user: User?
    
    private let userDefaultsKey = "currentUser"
    
    func initializeUserIfNeeded() {
        if let savedUser = loadUser() {
            print("✅ User loaded from UserDefaults: \(savedUser.nickname)")
            DispatchQueue.main.async {
                self.user = savedUser
            }
        } else {
            print("⏩ No existing user found, creating new user...")
            let newUser = User(
                nickname: "Guest",
                profileImageURL: nil,
                bio: "소개글을 작성하세요",
                experience: 0,
                balance: 0,
                gems: 0,
                collectedVideos: [],
                playlists: []
            )
            saveUser(newUser)
            DispatchQueue.main.async {
                self.user = newUser
            }
            print("New user created: \(newUser)")
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
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            DispatchQueue.main.async {
                self.user = user
            }
            print("✅ User saved to UserDefaults.")
        } catch {
            print("Error encoding user: \(error)")
        }
    }
    
    func rewardUser(for video: Video) {
        guard var user = user else { return }
        
        print("수집 전 경험치 \(user.experience), 코인 \(user.balance)")
        
        // 등급에 따른 보상 계산
        let experienceReward = UserStatusManager.shared.getExperienceReward(for: video.rarity)
        let coinReward = UserStatusManager.shared.getCoinReward(for: video.rarity)
        
        user.experience += experienceReward
        user.balance += coinReward
        
        print("수집 후 경험치 \(user.experience), 코인 \(user.balance)")
        
        // 레벨 업데이트
        let newLevel = UserStatusManager.shared.calculateLevel(from: user.experience)
        print("🎉 경험치 획득: \(experienceReward), 코인 획득: \(coinReward)")
        print("🏆 새로운 레벨: \(newLevel)")
        
        // 변경된 사용자 정보를 즉시 저장
        
        print("새로운 유저 정보: \(user)")
        self.saveUser(user)
    }
}
