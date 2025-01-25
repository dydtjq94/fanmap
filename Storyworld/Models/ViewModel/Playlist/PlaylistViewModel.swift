//
//  PlaylistViewModel.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

class PlaylistViewModel: ObservableObject {
    @Published var playlists: [Playlist] = []
    private let userService = UserService.shared

    func loadPlaylists() {
        guard let user = userService.user else {
            print("⚠️ 유저 정보 없음.")
            playlists = []
            return
        }
        playlists = user.playlists
        print("✅ 플레이리스트 불러오기 완료: \(playlists.count)개")
    }
}
