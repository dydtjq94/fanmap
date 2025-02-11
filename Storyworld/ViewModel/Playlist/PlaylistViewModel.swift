//
//  PlaylistViewModel.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    private let playlistService = PlaylistService.shared

    func loadPlaylists() {
        playlists = playlistService.loadPlaylists()
        print("✅ 플레이리스트 불러오기 완료: \(playlists.count)개")
    }
}
