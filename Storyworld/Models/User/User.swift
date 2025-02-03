//
//  User.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import Foundation

struct User: Codable, Equatable {
    var id: UUID
    var email: String
    var nickname: String
    var profileImageURL: String?
    var bio: String?
    var experience: Int
    var balance: Int
    var gems: Int
    var collectedVideos: [CollectedVideo]
    var playlists: [Playlist]
}
