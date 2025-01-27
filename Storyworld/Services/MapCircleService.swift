//
//  MapCircleService.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import Foundation
import CoreLocation

final class MapCircleService {
    private let tileManager = TileManager()
    
    struct CircleData: Codable {
        let id: UUID
        let genre: VideoGenre
        let rarity: VideoRarity
        let location: CLLocationCoordinate2D
        let basePrice: Int   // 희귀도에 따른 기본 가격
        var lastDropTime: Date?  // 마지막 드롭 시간
        let cooldownTime: TimeInterval  // 드롭 제한 시간 (초 단위)
        
        private enum CodingKeys: String, CodingKey {
            case id, genre, rarity, latitude, longitude, basePrice, lastDropTime, cooldownTime
        }
        
        init(genre: VideoGenre, rarity: VideoRarity, location: CLLocationCoordinate2D, basePrice: Int, cooldownTime: TimeInterval, lastDropTime: Date?) {
            self.id = UUID()
            self.genre = genre
            self.rarity = rarity
            self.location = location
            self.basePrice = basePrice
            self.cooldownTime = cooldownTime
            self.lastDropTime = lastDropTime
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
        }
        
        // 희귀도에 따른 가격 반환 (static 추가)
        static func getPrice(for rarity: VideoRarity) -> Int {
            switch rarity {
            case .silver:
                return 100
            case .gold:
                return 1000
            case .diamond:
                return 10000
            case .ruby:
                return 50000
            }
        }
        
        // 희귀도에 따른 쿨다운 시간 반환 (static 추가)
        static func getCooldown(for rarity: VideoRarity) -> TimeInterval {
            switch rarity {
            case .silver:
                return TimeInterval([5 * 60, 10 * 60].randomElement()!)  // 5분 또는 10분
            case .gold:
                return TimeInterval([2 * 60 * 60, 4 * 60 * 60].randomElement()!)  // 2시간 또는 4시간
            case .diamond:
                return TimeInterval([8 * 60 * 60, 12 * 60 * 60].randomElement()!)  // 8시간 또는 12시간
            case .ruby:
                return TimeInterval(48 * 60 * 60)  // 48시간 (고정)
            }
        }
    }
    
    func createFilteredCircleData(visibleTiles: [Tile], tileManager: TileManager) -> [MapCircleService.CircleData] {
        var filteredCircles: [MapCircleService.CircleData] = []
        let genres: [VideoGenre] = [.entertainment, .talk, .music, .sports, .vlog, .fashion, .food, .education, .game]
        let rarityProbabilities: [(VideoRarity, Double)] = VideoRarity.allCases.map { ($0, $0.probability) }
        // 고정된 Zoom Level과 Length
        let fixedZoomLevel = Constants.Numbers.searchFixedZoomLevel
        
        for tile in visibleTiles {
            if let randomLocation = randomCoordinateInTile(tile: tile, zoomLevel: Double(fixedZoomLevel)) {
                guard let randomGenre = genres.randomElement() else {
                    print("❌ 랜덤 장르 생성 실패")
                    continue
                }
                
                let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)
                let basePrice = MapCircleService.CircleData.getPrice(for: randomRarity)
                let cooldownTime = MapCircleService.CircleData.getCooldown(for: randomRarity)

                let circle = MapCircleService.CircleData(
                    genre: randomGenre,
                    rarity: randomRarity,
                    location: randomLocation,
                    basePrice: basePrice,
                    cooldownTime: cooldownTime,
                    lastDropTime: nil // 초기 드롭 시간 없음
                )

                filteredCircles.append(circle)
                filteredCircles.append(circle)
            } else {
                print("❌ 랜덤 좌표 생성 실패 - Tile: \(tile)")
            }
        }
        return filteredCircles
    }
    
    /// 📍 랜덤 좌표 생성 (타일 내)
    func randomCoordinateInTile(tile: Tile, zoomLevel: Double) -> CLLocationCoordinate2D? {
        // 80% 확률로 좌표 생성
        let probability = Constants.Numbers.searchProbability
        guard Double.random(in: 0...1) <= probability else {
            print("❌ 랜덤 좌표 생성 실패 (확률 조건 미충족)")
            return nil
        }
        
        let n = pow(2.0, zoomLevel) // 줌 레벨에 따른 타일 개수
        
        // 타일의 경도 범위 계산
        let lonPerTile = 360.0 / n
        let tileMinLon = Double(tile.x) * lonPerTile - 180.0
        let tileMaxLon = tileMinLon + lonPerTile
        
        // 타일의 위도 범위 계산
        let tileMaxLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y) * 2.0 * .pi / n))
        let tileMinLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y + 1) * 2.0 * .pi / n))
        
        // 랜덤 좌표 생성
        let randomLat = Double.random(in: tileMinLat...tileMaxLat)
        let randomLon = Double.random(in: tileMinLon...tileMaxLon)
        
        return CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon)
    }
    
    // 확률 기반으로 희귀도 선택
    private func randomRarityBasedOnProbability(_ probabilities: [(VideoRarity, Double)]) -> VideoRarity {
        let totalProbability = probabilities.reduce(0) { $0 + $1.1 }
        let randomValue = Double.random(in: 0...totalProbability)
        
        var cumulativeProbability: Double = 0
        for (rarity, probability) in probabilities {
            cumulativeProbability += probability
            if randomValue <= cumulativeProbability {
                return rarity
            }
        }
        
        // 기본값 반환 (논리적으로 이곳에 도달하지 않음)
        return .silver
    }
}

extension MapCircleService.CircleData {
    
    /// 드롭 여부 확인
    func isRecentlyDropped() -> Bool {
        guard let lastDropTime = lastDropTime else {
            return false  // 한 번도 드롭되지 않음
        }
        let currentTime = Date()
        let timeSinceLastDrop = currentTime.timeIntervalSince(lastDropTime)
        return timeSinceLastDrop < cooldownTime  // 쿨다운 시간 내인지 확인
    }
}
