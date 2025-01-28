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
    private let storageKey = "tileDataCache" // UserDefaults 키
    private var tileData: [String: TileManager.TileInfo] = [:]
    
    init() {
        self.tileData = loadTileData() // 캐시에서 로드
        resetTileVisibility()
    }
    
    /// 🔹 모든 타일의 isVisible을 false로 초기화
    func resetTileVisibility() {
        for (key, tileInfo) in tileData {
            var updatedTileInfo = tileInfo
            updatedTileInfo.isVisible = false
            tileData[key] = updatedTileInfo
        }
        saveTileData()
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
    
    /// 🔹 타일 정보를 저장 (중복 방지 및 가시성 업데이트 포함)
    func saveTileInfo(for tile: Tile, layerData: [MapCircleService.CircleData], isVisible: Bool) {
        let tileKey = tile.toKey()
        
        if let existingTileInfo = tileData[tileKey] {
            if existingTileInfo.isVisible {
                print("✔️ 이미 isVisible이 true인 타일, 저장 생략: \(tileKey)")
                return
            } else {
                tileData[tileKey]?.isVisible = true
                saveTileData()
                return
            }
        }

        // 🔥 CircleData 생성 시 tileKey 추가
        let updatedLayerData = layerData.map { circle in
            MapCircleService.CircleData(
                genre: circle.genre,
                rarity: circle.rarity,
                location: circle.location,
                basePrice: circle.basePrice,
                cooldownTime: circle.cooldownTime,
                lastDropTime: circle.lastDropTime,
                tileKey: tileKey  // 🔥 타일 정보를 직접 저장
            )
        }

        tileData[tileKey] = TileManager.TileInfo(layerData: updatedLayerData, isVisible: isVisible)
        saveTileData()
        print("💾 새 타일 데이터 저장 완료: \(tileKey)")
    }
    
    /// 🔹 특정 타일의 가시성 상태 업데이트
    func updateTileVisibility(for tile: Tile, isVisible: Bool) {
        let tileKey = tile.toKey()
        if var existingTileInfo = tileData[tileKey] {
            existingTileInfo.isVisible = isVisible
            tileData[tileKey] = existingTileInfo
            saveTileData()
            print("👁️ 타일 가시성 업데이트: \(tileKey), isVisible: \(isVisible)")
        } else {
            print("⚠️ 업데이트할 타일 정보가 존재하지 않음: \(tileKey)")
        }
    }
    
    /// 🔹 여러 타일 정보를 한 번에 저장
    func saveMultipleTileInfo(tileInfoDict: [Tile: [MapCircleService.CircleData]], isVisible: Bool) {
        var updated = false
        
        for (tile, layerData) in tileInfoDict {
            let tileKey = tile.toKey()
            
            if let existingTileInfo = tileData[tileKey] {
                if existingTileInfo.isVisible {
                    print("✔️ 이미 isVisible이 true인 타일, 저장 생략: \(tileKey)")
                    continue
                } else {
                    tileData[tileKey]?.isVisible = true
                    updated = true
                    print("🔄 기존 타일의 가시성 업데이트: \(tileKey)")
                }
            } else {
                tileData[tileKey] = TileManager.TileInfo(layerData: layerData, isVisible: isVisible)
                updated = true
                print("💾 새 타일 데이터 저장 완료: \(tileKey)")
            }
        }
        
        if updated {
            saveTileData()
            print("✅ 여러 타일 데이터 저장 완료")
        } else {
            print("⚠️ 저장할 타일 데이터 없음")
        }
    }
    
    /// 🔹 여러 타일의 가시성 상태를 한 번에 업데이트
    func batchUpdateTileVisibility(tiles: [Tile], isVisible: Bool) {
        var updated = false
        var updatedTileKeys: [String] = []
        
        for tile in tiles {
            let tileKey = tile.toKey()
            
            if var existingTileInfo = tileData[tileKey] {
                print("🔍 기존 타일 정보: \(existingTileInfo)")
                if existingTileInfo.isVisible == isVisible {
                    print("✔️ 이미 동일한 가시성 상태인 타일: \(tileKey), 생략")
                    continue
                }
                
                existingTileInfo.isVisible = isVisible
                tileData[tileKey] = existingTileInfo
                print("🔄 업데이트된 타일 정보: \(existingTileInfo)")
                
                updatedTileKeys.append(tileKey)
                updated = true
            } else {
                print("⚠️ 업데이트할 타일 정보 없음: \(tileKey)")
            }
        }
        
        if updated {
            print("📝 업데이트된 타일 키 목록: \(updatedTileKeys)")
            
            // 저장 직전 tileData 상태 출력
            print("🔄 저장 직전 타일 데이터: \(tileData.map { "\($0.key): \($0.value)" })")
            
            saveTileData()
            print("✅ 업데이트된 타일 저장 완료")
        } else {
            print("⚠️ 변경된 타일 없음")
        }
    }
    
    // =======================
    // 🔥 여기서부터 캐시 관리 기능
    // =======================
    
    /// 🔹 타일 데이터 저장 (UserDefaults 사용)
    private func saveTileData() {
        let encoder = JSONEncoder()
        do {
            let encoded = try encoder.encode(tileData)
            UserDefaults.standard.set(encoded, forKey: storageKey)
            print("💾 타일 데이터 저장 완료")
        } catch {
            print("❌ 타일 데이터 저장 실패: \(error.localizedDescription)")
        }
    }
    
    /// 🔹 타일 데이터 로드 (UserDefaults에서 복원)
    private func loadTileData() -> [String: TileManager.TileInfo] {
        let decoder = JSONDecoder()
        guard let savedData = UserDefaults.standard.data(forKey: storageKey) else {
            print("📂 저장된 타일 데이터가 없음")
            return [:]
        }
        do {
            let decoded = try decoder.decode([String: TileManager.TileInfo].self, from: savedData)
            print("📂 타일 데이터 로드 완료")
            return decoded
        } catch {
            print("❌ 타일 데이터 로드 실패: \(error.localizedDescription)")
            return [:]
        }
    }
    
    /// 🔹 캐시 초기화
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        tileData.removeAll()
        print("🗑️ 타일 데이터 캐시 초기화 완료")
    }
    
    /// 특정 CircleData의 tileKey를 기반으로 lastDropTime 업데이트
    func updateLastDropTime(for circleData: MapCircleService.CircleData) {
        let tileKey = circleData.tileKey  // 🔥 tileKey를 가져옴

        guard var tileInfo = tileData[tileKey] else {
            print("⚠️ \(tileKey)에 해당하는 타일 정보가 없습니다.")
            return
        }

        // 🔥 해당 타일의 CircleData를 업데이트
        var updatedLayerData = tileInfo.layerData.map { circle -> MapCircleService.CircleData in
            if circle.id == circleData.id {
                // 같은 CircleData를 찾으면 lastDropTime 업데이트
                var updatedCircle = circle
                updatedCircle.lastDropTime = Date()  // 현재 시간으로 설정
                print("✅ CircleData 업데이트 완료: \(updatedCircle.id), lastDropTime: \(updatedCircle.lastDropTime!)")
                return updatedCircle
            } else {
                return circle
            }
        }

        // 업데이트된 데이터를 저장
        tileInfo.layerData = updatedLayerData
        tileData[tileKey] = tileInfo  // 변경된 tileInfo 저장
        saveTileData()  // UserDefaults에 저장

        print("💾 타일 데이터 업데이트 완료: \(tileKey)")
    }
}
