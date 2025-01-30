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
                return Int.random(in: 50...150)
            case .gold:
                return Int.random(in: 250...350)
            case .diamond:
                return Int.random(in: 1000...2000)
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
    //    let genres: [VideoGenre] = [.entertainment, .talk, .music, .sports, .vlog, .fashion, .food, .education, .game]
        let genres: [VideoGenre] = [.talk]
        let rarityProbabilities: [(VideoRarity, Double)] = VideoRarity.allCases.map { ($0, $0.probability) }
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
                let tileKey = tile.toKey()  // 🔥 타일 키 추가

                let circle = MapCircleService.CircleData(
                    genre: randomGenre,
                    rarity: randomRarity,
                    location: randomLocation,
                    basePrice: basePrice,
                    cooldownTime: cooldownTime,
                    lastDropTime: nil, // 초기 드롭 시간 없음
                    tileKey: tileKey  // 🔥 타일 키 포함
                )

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
//
//extension MapCircleService.CircleData {
//    
//    /// 드롭 여부 확인
//    func isRecentlyDropped() -> Bool {
//        guard let lastDropTime = lastDropTime else {
//            return false  // 한 번도 드롭되지 않음
//        }
//        let currentTime = Date()
//        let timeSinceLastDrop = currentTime.timeIntervalSince(lastDropTime)
//        return timeSinceLastDrop < cooldownTime  // 쿨다운 시간 내인지 확인
//    }
//}
