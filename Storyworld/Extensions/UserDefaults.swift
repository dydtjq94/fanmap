//
//  UserDefaults+VideoStorage.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import CoreLocation

extension UserDefaults {
    private enum Keys {
        static let currentUser = "currentUser"
        static let collectedVideos = "collectedVideos"
        static let playlists = "playlists"
    }

    // ✅ 유저 정보 저장
    func saveUser(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            set(encoded, forKey: Keys.currentUser)
        }
    }

    // ✅ 저장된 유저 정보 불러오기
    func loadUser() -> User? {
        guard let savedData = data(forKey: Keys.currentUser),
              let decodedUser = try? JSONDecoder().decode(User.self, from: savedData) else {
            return nil
        }
        return decodedUser
    }

    // ✅ Collected Videos 저장
    func saveCollectedVideos(_ videos: [CollectedVideo]) {
        if let encoded = try? JSONEncoder().encode(videos) {
            set(encoded, forKey: Keys.collectedVideos)
        }
    }

    // ✅ Collected Videos 불러오기
    func loadCollectedVideos() -> [CollectedVideo] {
        guard let savedData = data(forKey: Keys.collectedVideos),
              let decodedVideos = try? JSONDecoder().decode([CollectedVideo].self, from: savedData) else {
            return []
        }
        return decodedVideos
    }

    // ✅ Playlists 저장
    func savePlaylists(_ playlists: [Playlist]) {
        if let encoded = try? JSONEncoder().encode(playlists) {
            set(encoded, forKey: Keys.playlists)
        }
    }

    // ✅ Playlists 불러오기
    func loadPlaylists() -> [Playlist] {
        guard let savedData = data(forKey: Keys.playlists),
              let decodedPlaylists = try? JSONDecoder().decode([Playlist].self, from: savedData) else {
            return []
        }
        return decodedPlaylists
    }
}
