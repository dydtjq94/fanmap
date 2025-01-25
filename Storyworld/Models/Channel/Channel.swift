//
//  Channel.swift
//  Storyworld
//
//  Created by peter on 1/17/25.
//

import Foundation

struct Channel: Codable, Equatable {
    let id: String
    let name: String
    let profileImageUrl: String
    let description: String
    let platform: ChannelPlatform
    let subscriberCount: Int
    let videoCount: Int
    let creationDate: Date
    
    static func getChannelName(by id: String) -> String {
        if let channel = ChannelDummyData.sampleChannels.first(where: { $0.id == id }) {
            return channel.name
        }
        return "Unknown Channel"
    }
}
