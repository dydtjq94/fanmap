//
//  SheetManager.swift
//  Storyworld
//
//  Created by peter on 1/23/25.
//

import SwiftUI

class SheetManager: ObservableObject {
    @Published var showPlaylistDetail: Bool = false
    @Published var showAddVideoSheet: Bool = false
    var selectedPlaylist: Playlist?
    
    func presentPlaylistDetail(for playlist: Playlist) {
        self.selectedPlaylist = playlist
        self.showPlaylistDetail = true
    }

    func dismissPlaylistDetail() {
        self.selectedPlaylist = nil
        self.showPlaylistDetail = false
    }
    
    func presentAddVideoSheet() {
        self.showAddVideoSheet = true
    }

    func dismissAddVideoSheet() {
        self.showAddVideoSheet = false
    }
}
