//
//  CircleData.swift
//  Storyworld
//
//  Created by peter on 1/30/25.
//


import Foundation
import CoreLocation

struct CircleData: Codable {
    let id: UUID
    let genre: VideoGenre
    let rarity: VideoRarity
    let location: CLLocationCoordinate2D
    let basePrice: Int
    var lastDropTime: Date?
    let cooldownTime: TimeInterval
    let tileKey: String  // 🔥 타일 정보를 직접 저장!

    private enum CodingKeys: String, CodingKey {
        case id, genre, rarity, latitude, longitude, basePrice, lastDropTime, cooldownTime, tileKey
    }

    init(genre: VideoGenre, rarity: VideoRarity, location: CLLocationCoordinate2D, basePrice: Int, cooldownTime: TimeInterval, lastDropTime: Date?, tileKey: String) {
        self.id = UUID()
        self.genre = genre
        self.rarity = rarity
        self.location = location
        self.basePrice = basePrice
        self.cooldownTime = cooldownTime
        self.lastDropTime = lastDropTime
        self.tileKey = tileKey  // 🔥 생성 시 타일 정보 저장
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        genre = try container.decode(VideoGenre.self, forKey: .genre)
        rarity = try container.decode(VideoRarity.self, forKey: .rarity)
        let latitude = try container.decode(Double.self, forKey: .latitude)
        let longitude = try container.decode(Double.self, forKey: .longitude)
        location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        basePrice = try container.decode(Int.self, forKey: .basePrice)
        cooldownTime = try container.decode(TimeInterval.self, forKey: .cooldownTime)
        lastDropTime = try? container.decode(Date.self, forKey: .lastDropTime)
        tileKey = try container.decode(String.self, forKey: .tileKey)  // 🔥 디코딩 시 타일 정보 로드
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(genre, forKey: .genre)
        try container.encode(rarity, forKey: .rarity)
        try container.encode(location.latitude, forKey: .latitude)
        try container.encode(location.longitude, forKey: .longitude)
        try container.encode(basePrice, forKey: .basePrice)
        try container.encode(cooldownTime, forKey: .cooldownTime)
        try? container.encode(lastDropTime, forKey: .lastDropTime)
        try container.encode(tileKey, forKey: .tileKey)  // 🔥 인코딩 시 타일 정보 저장
    }
    
    // 희귀도에 따른 가격 반환 (static 추가)
    static func getPrice(for rarity: VideoRarity) -> Int {
        switch rarity {
        case .silver:
            return Int.random(in: 80...120)
        case .gold:
            return Int.random(in: 200...400)
        case .diamond:
            return Int.random(in: 1500...2500)
        case .ruby:
            return Int.random(in: 50000...100000)
        }
    }
    
    // 희귀도에 따른 쿨다운 시간 반환 (static 추가)
    static func getCooldown(for rarity: VideoRarity) -> TimeInterval {
        switch rarity {
        case .silver:
            return TimeInterval([10 * 60, 30 * 60].randomElement()!)  // 10분 또는 30분
        case .gold:
            return TimeInterval([1 * 60 * 60, 2 * 60 * 60, 4 * 60 * 60].randomElement()!)  // 2시간 또는 4시간
        case .diamond:
            return TimeInterval([8 * 60 * 60, 12 * 60 * 60].randomElement()!)  // 8시간 또는 12시간
        case .ruby:
            return TimeInterval(24 * 60 * 60)  // 48시간 (고정)
        }
    }
}
