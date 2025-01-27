//
//  ChannelDummyData.swift
//  Storyworld
//
//  Created by peter on 1/17/25.
//

import Foundation

struct ChannelDummyData {
    static let sampleChannels: [Channel] = [
        Channel(
            id: "UCUj6rrhMTR9pipbAWBAMvUQ",
            name: "침착맨",
            profileImageUrl: "https://example.com/images/chimchakman.png",
            description: "침착맨의 다양한 영상들",
            platform: .youtube,
            subscriberCount: 1000000,
            videoCount: 250,
            creationDate: ISO8601DateFormatter().date(from: "2015-03-12T10:00:00Z")!
        ),
        Channel(
            id: "channel_002",
            name: "허팝",
            profileImageUrl: "https://example.com/images/heopop.png",
            description: "허팝의 모험과 실험 영상",
            platform: .youtube,
            subscriberCount: 1500000,
            videoCount: 300,
            creationDate: ISO8601DateFormatter().date(from: "2014-07-05T15:30:00Z")!
        ),
        Channel(
            id: "channel_003",
            name: "또모TOWMOO",
            profileImageUrl: "https://example.com/images/gamemong.png",
            description: "게임을 사랑하는 사람들의 채널",
            platform: .twitch,
            subscriberCount: 500000,
            videoCount: 120,
            creationDate: ISO8601DateFormatter().date(from: "2017-01-20T18:45:00Z")!
        )
    ]
}
