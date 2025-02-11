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
        let collectedVideos = UserDefaults.standard.loadCollectedVideos() // ✅ UserDefaults에서 직접 가져오기

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
        let collectedVideos = UserDefaults.standard.loadCollectedVideos() // ✅ UserDefaults에서 직접 가져오기

        let filteredVideos = collectedVideos
            .filter { !playlist.videoIds.contains($0.video.videoId) }
            .sorted { $0.collectedDate > $1.collectedDate }

        self.videosNotInPlaylist = filteredVideos
    }
}
