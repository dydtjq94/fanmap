//
//  TileService.swift
//  Storyworld
//
//  Created by peter on 1/13/25.
//

import Foundation
import CoreLocation

final class TileService {
    private let tileManager = TileManager()
    private let cacheManager = TileCacheManager()
    private var tileData: [String: TileManager.TileInfo] = [:]
    
    init() {
        self.tileData = cacheManager.loadTileData()
        resetTileVisibility()
    }
    
    // 모든 타일의 isVisible을 false로 초기화
    func resetTileVisibility() {
        for (key, tileInfo) in tileData {
            var updatedTileInfo = tileInfo
            updatedTileInfo.isVisible = false
            tileData[key] = updatedTileInfo
        }
        cacheManager.saveTileData(tileData)
        print("🔄 모든 타일의 가시성 초기화 완료 (isVisible = false)")
    }
    
    // 주어진 중심 좌표를 기준으로 범위 내 타일 반환
    func tilesInRange(center: CLLocationCoordinate2D) -> [Tile] {
        return tileManager.tilesInRange(center: center)
    }
    
    // 특정 타일의 정보를 가져오기
    func getTileInfo(for tile: Tile) -> TileManager.TileInfo? {
        return tileData[tile.toKey()]
    }
    
    // 타일 정보를 저장 (중복 방지 및 가시성 업데이트 포함)
    func saveTileInfo(for tile: Tile, layerData: [VideoService.CircleData], isVisible: Bool) {
        let tileKey = tile.toKey()
        
        if let existingTileInfo = tileData[tileKey] {
            if existingTileInfo.isVisible {
                print("✔️ 이미 isVisible이 true인 타일, 저장 생략: \(tileKey)")
                return
            } else {
                // 기존 타일의 가시성 업데이트 (새로 그릴 필요가 있음)
                tileData[tileKey]?.isVisible = true
                cacheManager.saveTileData(tileData)
                print("🔄 기존 타일의 가시성 업데이트: \(tileKey)")
                return
            }
        }
        
        // 새 타일 정보 저장
        tileData[tileKey] = TileManager.TileInfo(layerData: layerData, isVisible: isVisible)
        cacheManager.saveTileData(tileData) // 캐시에 저장
        print("💾 새 타일 데이터 저장 완료: \(tileKey)")
    }
    
    // 특정 타일의 가시성 상태 업데이트
    func updateTileVisibility(for tile: Tile, isVisible: Bool) {
        let tileKey = tile.toKey()
        if var existingTileInfo = tileData[tileKey] {
            existingTileInfo.isVisible = isVisible
            tileData[tileKey] = existingTileInfo
            cacheManager.saveTileData(tileData)
            print("👁️ 타일 가시성 업데이트: \(tileKey), isVisible: \(isVisible)")
        } else {
            print("⚠️ 업데이트할 타일 정보가 존재하지 않음: \(tileKey)")
        }
    }
}
