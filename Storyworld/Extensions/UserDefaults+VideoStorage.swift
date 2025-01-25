//
//  UserDefaults+VideoStorage.swift
//  Storyworld
//
//  Created by peter on 1/9/25.
//

import Foundation
import CoreLocation

extension UserDefaults {
    private enum Keys {
        static let videos = "videos"
        static let lastUpdated = "lastUpdated"
    }

    func saveVideos(_ videos: [Video]) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(videos) {
            set(encoded, forKey: Keys.videos)
        }
        set(Date(), forKey: Keys.lastUpdated)
    }

    func loadVideos() -> [Video]? {
        guard let data = data(forKey: Keys.videos) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode([Video].self, from: data)
    }

    func isDataExpired(expirationInterval: TimeInterval) -> Bool {
        guard let lastUpdated = object(forKey: Keys.lastUpdated) as? Date else {
            return true // 데이터를 저장한 적이 없는 경우
        }
        return Date().timeIntervalSince(lastUpdated) > expirationInterval
    }
    
    func removeVideo(byId videoId: String) {
        var videos = loadVideos() ?? []
        videos.removeAll { $0.videoId == videoId }
        saveVideos(videos)
    }

    func clearVideos() {
        removeObject(forKey: Keys.videos)
        removeObject(forKey: Keys.lastUpdated)
    }
    
    func getObject<T: Decodable>(forKey key: String, as type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        return try? decoder.decode(type, from: data)
    }

    func setObject<T: Encodable>(_ object: T, forKey key: String) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(object) {
            set(data, forKey: key)
        }
    }
}
