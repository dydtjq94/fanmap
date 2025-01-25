//
//  VideoDummyData.swift
//  Storyworld
//
//  Created by peter on 1/17/25.
//

import Foundation

struct VideoDummyData {
    static let sampleVideos: [Video] = [
        // Action/Adventure
        Video(videoId: "ZoeQT2tfMf0", title: "Action Begins (Silver)", description: "An action-packed adventure with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-01T10:00:00Z"), genre: .entertainment, rarity: .silver),
        Video(videoId: "video_002", title: "Action Intensifies (Gold)", description: "An action-packed adventure with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-02T10:00:00Z"), genre: .entertainment, rarity: .gold),
        Video(videoId: "video_003", title: "Action Hero (Diamond)", description: "An action-packed adventure with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-03T10:00:00Z"), genre: .entertainment, rarity: .diamond),
        Video(videoId: "video_004", title: "Ultimate Action (Red Diamond)", description: "An action-packed adventure with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-04T10:00:00Z"), genre: .entertainment, rarity: .ruby),
        
        // Animation
        Video(videoId: "video_005", title: "돌아온 재즈 고막 여친", description: "A delightful animated story with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/x7bn9r5mF_Q/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-05T10:00:00Z"), genre: .talk, rarity: .silver),
        Video(videoId: "video_006", title: "돌아온 재즈 고막 여친", description: "A delightful animated story with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-06T10:00:00Z"), genre: .talk, rarity: .gold),
        Video(videoId: "video_007", title: "돌아온 재즈 고막 여친", description: "A delightful animated story with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-07T10:00:00Z"), genre: .talk, rarity: .diamond),
        Video(videoId: "video_008", title: "돌아온 재즈 고막 여친", description: "A delightful animated story with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/mqdefault.jpg", channelId: "channel_003", publishDate: ISO8601DateFormatter().date(from: "2025-01-08T10:00:00Z"), genre: .talk, rarity: .ruby),
        
        // Comedy
        Video(videoId: "video_009", title: "Comedy Begins (Silver)", description: "A hilarious comedy with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_009/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-09T10:00:00Z"), genre: .music, rarity: .silver),
        Video(videoId: "video_010", title: "Comedy Gold (Gold)", description: "A hilarious comedy with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_010/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-10T10:00:00Z"), genre: .music, rarity: .gold),
        Video(videoId: "video_011", title: "Comedy Diamond (Diamond)", description: "A hilarious comedy with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_011/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-11T10:00:00Z"), genre: .music, rarity: .diamond),
        Video(videoId: "video_012", title: "Comedy Legend (Red Diamond)", description: "A hilarious comedy with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_012/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-12T10:00:00Z"), genre: .music, rarity: .ruby),
        
        // Horror/Thriller
        Video(videoId: "video_013", title: "Horror Night (Silver)", description: "A spine-chilling horror story with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_013/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-13T10:00:00Z"), genre: .sports, rarity: .silver),
        Video(videoId: "video_014", title: "Horror Masterpiece (Gold)", description: "A spine-chilling horror story with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_014/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-14T10:00:00Z"), genre: .sports, rarity: .gold),
        Video(videoId: "video_015", title: "Horror Legend (Diamond)", description: "A spine-chilling horror story with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_015/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-15T10:00:00Z"), genre: .sports, rarity: .diamond),
        Video(videoId: "video_016", title: "Horror Supreme (Red Diamond)", description: "A spine-chilling horror story with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/ZoeQT2tfMf0/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-16T10:00:00Z"), genre: .sports, rarity: .ruby),
        
        // Documentary/War
        Video(videoId: "video_017", title: "Documenting History (Silver)", description: "A thought-provoking documentary with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_017/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-17T10:00:00Z"), genre: .vlog, rarity: .silver),
        Video(videoId: "video_018", title: "Documentary Gold (Gold)", description: "A thought-provoking documentary with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_018/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-18T10:00:00Z"), genre: .vlog, rarity: .gold),
        Video(videoId: "dfdfsve", title: "[결말포함]식당 알바라고 개무시하는 친구들,며칠 뒤 재벌상속녀가 되어버린 여고생ㅋㅋㅋ", description: "A thought-provoking documentary with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/bVriY-mrmX8/mqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-19T10:00:00Z"), genre: .vlog, rarity: .diamond),
        Video(videoId: "video_020", title: "Documentary Supreme (Red Diamond)", description: "A thought-provoking documentary with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_020/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-20T10:00:00Z"), genre: .vlog, rarity: .ruby),
        
        // Sci-Fi/Fantasy
        Video(videoId: "video_021", title: "Sci-Fi Journey (Silver)", description: "An out-of-this-world story with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_021/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-21T10:00:00Z"), genre: .fashion, rarity: .silver),
        Video(videoId: "video_022", title: "Fantasy Saga (Gold)", description: "An out-of-this-world story with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_022/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-22T10:00:00Z"), genre: .fashion, rarity: .gold),
        Video(videoId: "video_023", title: "Sci-Fi Legend (Diamond)", description: "An out-of-this-world story with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_023/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-23T10:00:00Z"), genre: .fashion, rarity: .diamond),
        Video(videoId: "video_024", title: "Ultimate Sci-Fi (Red Diamond)", description: "An out-of-this-world story with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_024/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-24T10:00:00Z"), genre: .fashion, rarity: .ruby),
        
        // Drama
        Video(videoId: "video_025", title: "Drama Classic (Silver)", description: "A captivating drama with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_025/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-25T10:00:00Z"), genre: .food, rarity: .silver),
        Video(videoId: "video_026", title: "Golden Drama (Gold)", description: "A captivating drama with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_026/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-26T10:00:00Z"), genre: .food, rarity: .gold),
        Video(videoId: "video_027", title: "Dramatic Legend (Diamond)", description: "A captivating drama with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_027/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-27T10:00:00Z"), genre: .food, rarity: .diamond),
        Video(videoId: "video_028", title: "Ultimate Drama (Red Diamond)", description: "A captivating drama with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_028/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-28T10:00:00Z"), genre: .food, rarity: .ruby),
        
        // Romance
        Video(videoId: "video_029", title: "Romantic Story (Silver)", description: "A heartwarming romance with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_029/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-29T10:00:00Z"), genre: .education, rarity: .silver),
        Video(videoId: "video_030", title: "Golden Romance (Gold)", description: "A heartwarming romance with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_030/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-30T10:00:00Z"), genre: .education, rarity: .gold),
        Video(videoId: "video_031", title: "Romantic Legend (Diamond)", description: "A heartwarming romance with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_031/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-01-31T10:00:00Z"), genre: .education, rarity: .diamond),
        Video(videoId: "video_032", title: "Ultimate Romance (Red Diamond)", description: "A heartwarming romance with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_032/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-02-01T10:00:00Z"), genre: .education, rarity: .ruby),
        
        // Unknown
        Video(videoId: "video_033", title: "Unknown Silver (Silver)", description: "A mysterious unknown story with silver rarity.", thumbnailURL: "https://img.youtube.com/vi/video_033/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-02-02T10:00:00Z"), genre: .game, rarity: .silver),
        Video(videoId: "video_034", title: "Unknown Gold (Gold)", description: "A mysterious unknown story with gold rarity.", thumbnailURL: "https://img.youtube.com/vi/video_034/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-02-03T10:00:00Z"), genre: .game, rarity: .gold),
        Video(videoId: "video_035", title: "Unknown Diamond (Diamond)", description: "A mysterious unknown story with diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_035/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-02-04T10:00:00Z"), genre: .game, rarity: .diamond),
        Video(videoId: "video_036", title: "Ultimate Unknown (Red Diamond)", description: "A mysterious unknown story with red diamond rarity.", thumbnailURL: "https://img.youtube.com/vi/video_036/hqdefault.jpg", channelId: "channel_001", publishDate: ISO8601DateFormatter().date(from: "2025-02-05T10:00:00Z"), genre: .game, rarity: .ruby)
        
    ]
}
