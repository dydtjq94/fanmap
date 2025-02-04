//
//  UserDefaults+VideoStorage.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import CoreLocation

extension UserDefaults {
    private static let playlistsKey = "playlists"

    // ✅ 플레이리스트 저장
    func savePlaylists(_ playlists: [Playlist]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(playlists)
            self.set(data, forKey: UserDefaults.playlistsKey)
        } catch {
            print("❌ UserDefaults에 playlists 저장 실패: \(error.localizedDescription)")
        }
    }

    // ✅ 플레이리스트 불러오기
    func loadPlaylists() -> [Playlist] {
        guard let data = self.data(forKey: UserDefaults.playlistsKey) else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([Playlist].self, from: data)
        } catch {
            print("❌ UserDefaults에서 playlists 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    private static let collectedVideosKey = "collectedVideos"

    // ✅ 수집된 영상 저장
    func saveCollectedVideos(_ videos: [CollectedVideo]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(videos)
            self.set(data, forKey: UserDefaults.collectedVideosKey)
        } catch {
            print("❌ UserDefaults에 collectedVideos 저장 실패: \(error.localizedDescription)")
        }
    }

    // ✅ 수집된 영상 불러오기
    func loadCollectedVideos() -> [CollectedVideo] {
        guard let data = self.data(forKey: UserDefaults.collectedVideosKey) else { return [] }
        do {
            let decoder = JSONDecoder()
            return try decoder.decode([CollectedVideo].self, from: data)
        } catch {
            print("❌ UserDefaults에서 collectedVideos 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
}
