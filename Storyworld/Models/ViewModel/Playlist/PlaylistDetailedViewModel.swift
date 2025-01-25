//
//  PlaylistDetailedViewModel.swift
//  Storyworld
//
//  Created by peter on 1/23/25.
//

import SwiftUI

class PlaylistDetailedViewModel: ObservableObject {
    @Published var videosInPlaylist: [CollectedVideo] = []
    @Published var videosNotInPlaylist: [CollectedVideo] = []

    private let userService = UserService.shared

    func loadVideosInPlaylist(for playlist: Playlist) {
        guard let user = userService.user else {
            print("⚠️ 유저 정보 없음.")
            return
        }

        let collectedVideos = user.collectedVideos
        
        let filteredVideos = collectedVideos
            .filter { playlist.videoIds.contains($0.video.videoId) }
            .sorted { $0.collectedDate > $1.collectedDate }

        if self.videosInPlaylist != filteredVideos {
            self.videosInPlaylist = filteredVideos
            print("✅ 플레이리스트 내 영상 업데이트됨: \(filteredVideos.count)개")
        } else {
            print("ℹ️ 변경사항 없음, 영상 개수: \(filteredVideos.count)개")
        }
    }

    func loadVideosNotInPlaylist(for playlist: Playlist) {
        guard let user = userService.user else {
            print("⚠️ 유저 정보 없음.")
            return
        }

        let collectedVideos = user.collectedVideos
        
        let filteredVideos = collectedVideos
            .filter { !playlist.videoIds.contains($0.video.videoId) }
            .sorted { $0.collectedDate > $1.collectedDate }

        self.videosNotInPlaylist = filteredVideos
    }
}
