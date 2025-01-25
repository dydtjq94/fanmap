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
            self.user = savedUser
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
            self.user = newUser
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
}
