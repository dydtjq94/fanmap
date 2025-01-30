//
//  PlaylistService.swift
//  Storyworld
//
//  Created by peter on 1/23/25.
//

import Foundation
import UIKit

class PlaylistService {
    static let shared = PlaylistService()
    private let userService = UserService.shared
    
    private func savePlaylists(_ playlists: [Playlist]) {
        guard var user = userService.user else { return }
        user.playlists = playlists
        userService.saveUser(user)
        UserDefaults.standard.synchronize()  // 강제 동기화
    }
    
    func loadPlaylists() -> [Playlist] {
        guard let user = userService.user else {
            print("UserDefaults에서 유저 데이터 없음")
            return []
        }
        print("✅ User에서 플레이리스트 불러오기 완료: \(user.playlists.count) 개")
        return user.playlists
    }
    
    func addPlaylist(_ playlist: Playlist) {
        var playlists = loadPlaylists()
        playlists.append(playlist)
        savePlaylists(playlists)
    }

    func removePlaylist(_ id: UUID) {
        var playlists = loadPlaylists()
        playlists.removeAll { $0.id == id }
        savePlaylists(playlists)
    }
    
    func removeVideoFromPlaylist(_ video: CollectedVideo, playlist: Playlist) {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].videoIds.removeAll { $0 == video.video.videoId }
            UIImpactFeedbackGenerator.trigger(.heavy)
            savePlaylists(playlists)

            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    func addVideoToPlaylist(_ video: CollectedVideo, to playlist: Playlist) {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].videoIds.append(video.video.videoId)
            UIImpactFeedbackGenerator.trigger(.heavy)
            savePlaylists(playlists)
            
            print("✅ 저장 후 새 Playlist 상태: \(playlists[index].videoIds)")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    func updatePlaylistDetails(id: UUID, newName: String?, newDescription: String?) {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            if let newName = newName {
                playlists[index].name = newName
            }
            if let newDescription = newDescription {
                playlists[index].description = newDescription
            }
            savePlaylists(playlists)
            
            print("✅ 플레이리스트 업데이트됨: \(playlists[index].name), \(playlists[index].description ?? "설명 없음")")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
