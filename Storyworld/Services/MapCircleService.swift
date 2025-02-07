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
    
    func createFilteredCircleData(visibleTiles: [Tile], tileManager: TileManager) -> [CircleData] {
        var filteredCircles: [CircleData] = []
//        let channels: [VideoChannel] = VideoChannel.allCases
        
        // 🔥 특정 채널만 선택 (침착맨 & 우왁굳)
        let channels: [VideoChannel] = [.chimchakMan, .wowakGood, .wooJungIng]
        let rarityProbabilities: [(VideoRarity, Double)] = VideoRarity.allCases.map { ($0, $0.probability) }
        let fixedZoomLevel = Constants.Numbers.searchFixedZoomLevel

        for tile in visibleTiles {
            if let randomLocation = randomCoordinateInTile(tile: tile, zoomLevel: Double(fixedZoomLevel)) {
                guard let randomChannel = channels.randomElement() else {
                    print("❌ 랜덤 채널 생성 실패")
                    continue
                }
                
                let randomRarity = randomRarityBasedOnProbability(rarityProbabilities)
                let basePrice = CircleData.getPrice(for: randomRarity)
                let cooldownTime = CircleData.getCooldown(for: randomRarity)
                let tileKey = tile.toKey()  // 🔥 타일 키 추가

                let circle = CircleData(
                    channel: randomChannel,
                    rarity: randomRarity,
                    location: randomLocation,
                    basePrice: basePrice,
                    cooldownTime: cooldownTime,
                    lastDropTime: nil, // 초기 드롭 시간 없음
                    tileKey: tileKey  // 🔥 타일 키 포함
                )

                filteredCircles.append(circle)
            } else {
                print("❌ 랜덤 좌표 생성 실패 - Tile: \(tile) ")
            }
        }
        return filteredCircles
    }
    
    /// 📍 랜덤 좌표 생성 (타일 내)
    func randomCoordinateInTile(tile: Tile, zoomLevel: Double) -> CLLocationCoordinate2D? {
        let probability = Constants.Numbers.searchProbability
        guard Double.random(in: 0...1) <= probability else {
            print("❌ 랜덤 좌표 생성 실패 (확률 조건 미충족)")
            return nil
        }
        
        let n = pow(2.0, zoomLevel)
        let lonPerTile = 360.0 / n
        let tileMinLon = Double(tile.x) * lonPerTile - 180.0
        let tileMaxLon = tileMinLon + lonPerTile
        let tileMaxLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y) * 2.0 * .pi / n))
        let tileMinLat = 180.0 / .pi * atan(sinh(.pi - Double(tile.y + 1) * 2.0 * .pi / n))
        
        let randomLat = Double.random(in: tileMinLat...tileMaxLat)
        let randomLon = Double.random(in: tileMinLon...tileMaxLon)
        
        return CLLocationCoordinate2D(latitude: randomLat, longitude: randomLon)
    }
    
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
        
        return .silver
    }
}
