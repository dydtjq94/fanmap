//
//  VideoLayerMapManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import MapboxMaps
import UIKit

final class VideoLayerMapManager {
    private let mapView: MapView
    private let tileManager = TileManager()
    private let tileService = TileService()
    private var updateTimer: Timer? // ✅ 쿨다운 업데이트 타이머
    
    init(mapView: MapView) {
        self.mapView = mapView
        startCooldownUpdate() // ✅ 초기화 시 타이머 시작
    }
    
    func addGenreCircles(data: [CircleData], userLocation: CLLocationCoordinate2D, isScan: Bool = false) {
        for (index, item) in data.enumerated() {
            let location = item.location
            
            // 타일 정보 기반 고유 ID 생성
            let tile = tileManager.calculateTile(for: location, zoomLevel: Int(Constants.Numbers.searchFixedZoomLevel))
            let tileKey = tile.toKey()
            
            
            let sourceId = "source-\(tileKey)" // ✅ 스캔 여부 상관없이 동일한 형식 유지
            let glowLayerId = "glow-layer-\(tileKey)"
            let circleLayerId = "circle-layer-\(tileKey)"
            let symbolLayerId = "symbol-layer-\(tileKey)"
            
            // 드롭 여부에 따라 opacity 설정
            //            let opacityValue: Double = item.isRecentlyDropped() ? 0.3 : 1.0
            
            do {
                // GeoJSONSource 생성
                var feature = Feature(geometry: .point(Point(location)))
                
                // 🔥 CircleData를 JSON으로 변환하여 저장
                let currentTime = Date().timeIntervalSince1970 // 🔥 현재 시간 (초 단위)
                let encoder = JSONEncoder()
                if let encodedData = try? encoder.encode(item),
                   let jsonString = String(data: encodedData, encoding: .utf8) {
                    
                    // ✅ 남은 cooldown 계산 (0 이하이면 expired)
                    let elapsedTime = currentTime - (item.lastDropTime?.timeIntervalSince1970 ?? 0)
                    let remainingCooldown = max(item.cooldownTime - elapsedTime, 0)
                    
                    feature.properties = [
                        "circleData": .string(jsonString),
                        "genre": .string(item.genre.rawValue),
                        "rarity": .string(item.rarity.rawValue),
                        "remainingCooldown": .number(remainingCooldown) // ✅ 남은 시간 추가
                    ]
                }
                else {
                    print("❌ CircleData를 JSON으로 변환하는 데 실패했습니다.")
                }
                
                var geoJSONSource = GeoJSONSource(id: sourceId)
                geoJSONSource.data = .feature(feature)
                
                // Source 추가
                try mapView.mapboxMap.addSource(geoJSONSource)
                
                // Glow Layer 설정
                if item.rarity == .diamond || item.rarity == .ruby || item.rarity == .gold {
                    var glowLayer = CircleLayer(id: glowLayerId, source: sourceId)
                    glowLayer.circleColor = .expression(
                        Exp(.match,
                            Exp(.get, "rarity"),
                            VideoRarity.diamond.rawValue, StyleColor(VideoRarity.diamond.uiColor).rawValue,
                            VideoRarity.ruby.rawValue, StyleColor(VideoRarity.ruby.uiColor).rawValue,
                            VideoRarity.gold.rawValue, StyleColor(VideoRarity.gold.uiColor).rawValue,
                            StyleColor(UIColor.gray).rawValue // 기본값
                           )
                    )
                    glowLayer.circleRadius = .expression(
                        Exp(.match,
                            Exp(.get, "rarity"),
                            VideoRarity.gold.rawValue, 25.0,
                            VideoRarity.diamond.rawValue, 35.0,
                            VideoRarity.ruby.rawValue, 40.0,
                            0.0 // 기본값
                           )
                    )
                    glowLayer.circleBlur = .expression(
                        Exp(.match,
                            Exp(.get, "rarity"),
                            VideoRarity.gold.rawValue, 2.0,
                            VideoRarity.diamond.rawValue, 0.9,
                            VideoRarity.ruby.rawValue, 0.8,
                            0.0 // 기본값
                           )
                    )
                    glowLayer.circleOpacity = .expression(
                        Exp(.match,
                            Exp(.get, "rarity"),
                            VideoRarity.gold.rawValue, 1.0,
                            VideoRarity.diamond.rawValue, 1.0,
                            VideoRarity.ruby.rawValue, 1.0,
                            0.0 // 기본값
                           )
                    )
                    
                    try mapView.mapboxMap.addLayer(glowLayer)
                }
                
//                // Circle Layer 설정
//                var circleLayer = CircleLayer(id: circleLayerId, source: sourceId)
//                // ✅ "remainingCooldown"이 0보다 크면 흰색, 아니면 기존 장르 색상
//                circleLayer.circleColor = .expression(
//                    Exp(.match,
//                        Exp(.get, "genre"),
//                        VideoGenre.entertainment.rawValue, StyleColor(VideoGenre.entertainment.uiColor).rawValue,
//                        VideoGenre.talk.rawValue, StyleColor(VideoGenre.talk.uiColor).rawValue,
//                        VideoGenre.music.rawValue, StyleColor(VideoGenre.music.uiColor).rawValue,
//                        VideoGenre.sports.rawValue, StyleColor(VideoGenre.sports.uiColor).rawValue,
//                        VideoGenre.vlog.rawValue, StyleColor(VideoGenre.vlog.uiColor).rawValue,
//                        VideoGenre.fashion.rawValue, StyleColor(VideoGenre.fashion.uiColor).rawValue,
//                        VideoGenre.food.rawValue, StyleColor(VideoGenre.food.uiColor).rawValue,
//                        VideoGenre.education.rawValue, StyleColor(VideoGenre.education.uiColor).rawValue,
//                        VideoGenre.game.rawValue, StyleColor(VideoGenre.game.uiColor).rawValue,
//                        StyleColor(UIColor.gray).rawValue // 기본값
//                       )
//                )
//                circleLayer.circleRadius = .constant(14.0)
//                circleLayer.circleOpacity = .expression(
//                    Exp(.step,
//                        Exp(.get, "remainingCooldown"), // ✅ remainingCooldown 값을 기준으로 조건 적용
//                        1.0,  // 🔥 기본값 (쿨다운이 남아있으면 0.8 유지)
//                        0.1,  // ✅ remainingCooldown이 0 이하일 때
//                        0.5   // 🔥 투명도 낮춰서 흐려지게 설정
//                       )
//                )
                
                //                 Symbol Layer 설정
                let defaultIcon = "logo_small"          // 기본 아이콘
                let cooldownIcon = "logo_small_black"   // 쿨다운이 0 이하일 때 아이콘

                // 🟢 1. Mapbox에 이미지 추가 (두 개 모두 등록)
                try mapView.mapboxMap.addImage(
                    UIImage(named: defaultIcon)!,
                    id: defaultIcon
                )
                try mapView.mapboxMap.addImage(
                    UIImage(named: cooldownIcon)!,
                    id: cooldownIcon
                )

                // 🟡 2. Symbol Layer 설정
                var symbolLayer = SymbolLayer(id: symbolLayerId, source: sourceId)

                // 🟠 3. remainingCooldown 값에 따라 아이콘 변경
                symbolLayer.iconImage = .expression(
                    Exp(.step,
                        Exp(.get, "remainingCooldown"),
                        defaultIcon,
                        1, cooldownIcon
                    )
                )
                
                symbolLayer.iconSize = .constant(0.16) // 아이콘 크기 조정
                symbolLayer.iconAnchor = .constant(.center) // 아이콘 위치
                symbolLayer.iconAllowOverlap = .constant(true) // 중첩 허용
                symbolLayer.iconIgnorePlacement = .constant(true) // 배치 무시
                symbolLayer.iconOpacity = .constant(1.0)
                
//                symbolLayer.iconOpacity = .expression(
//                    Exp(.step,
//                        Exp(.get, "remainingCooldown"), // ✅ remainingCooldown 값을 기준으로 조건 적용
//                        1.0,  // 🔥 기본값 (쿨다운이 남아있으면 0.8 유지)
//                        1.0,  // ✅ remainingCooldown이 0 이하일 때
//                        1.0   // 🔥 투명도 낮춰서 흐려지게 설정
//                       )
//                )
                
                try mapView.mapboxMap.addLayer(symbolLayer)
                // Mapbox 지도에 레이어 추가
//                try mapView.mapboxMap.addLayer(circleLayer)
//                try mapView.mapboxMap.addLayer(symbolLayer, layerPosition: .above(circleLayer.id))
                
            } catch {
                print("❌ 레이어 추가 실패: \(error.localizedDescription)")
            }
        }
    }
    
    // SF Symbol 변환 및 Mapbox 등록
    private func registerSFSymbol(mapView: MapView, iconName: String, sfSymbolName: String, color: UIColor = .black, size: CGFloat = 64) {
        let scale = UIScreen.main.scale // 디스플레이의 스케일 (2x, 3x)
        let symbolSize = CGSize(width: size * scale, height: size * scale)
        
        // SF Symbol을 비트맵 이미지로 렌더링
        UIGraphicsBeginImageContextWithOptions(symbolSize, false, scale)
        if let _ = UIGraphicsGetCurrentContext(), // context를 사용하지 않음
           let sfSymbol = UIImage(systemName: sfSymbolName)?.withTintColor(color, renderingMode: .alwaysOriginal) {
            sfSymbol.draw(in: CGRect(origin: .zero, size: symbolSize))
            let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            if let renderedImage = renderedImage {
                do {
                    try mapView.mapboxMap.addImage(renderedImage, id: iconName)
                } catch {
                    print("❌ SF Symbol 이미지를 등록하는 데 실패했습니다: \(error.localizedDescription)")
                }
            }
        } else {
            UIGraphicsEndImageContext()
            print("❌ SF Symbol 이미지를 렌더링하는 데 실패했습니다.")
        }
    }
    
    private func registerIconImage(iconName: String, image: UIImage) {
        do {
            try mapView.mapboxMap.addImage(image, id: iconName)
        } catch {
            print("❌ 아이콘 이미지를 등록하는 데 실패했습니다: \(error.localizedDescription)")
        }
    }
    
    func startCooldownUpdate() {
        updateTimer?.invalidate() // 기존 타이머 제거
        updateTimer = Timer.scheduledTimer(withTimeInterval: 600.0, repeats: true) { [weak self] _ in
            self?.refreshAllTiles()
        }
    }
    
    // ✅ 현재 보이는 모든 타일을 업데이트
    func refreshAllTiles() {
        let visibleTiles = tileService.getAllVisibleTiles() // 🔥 현재 보이는 타일 가져오기
        for tile in visibleTiles {
            for circle in tile.layerData {
                self.updateVideoCircleLayer(for: circle) // 🔥 쿨다운 적용한 circle 업데이트
            }
        }
    }
    
    
    func removeAllVideoLayers() {
        do {
            let allLayers = try mapView.mapboxMap.allLayerIdentifiers
            for layer in allLayers {
                if layer.id.contains("circle-layer") || layer.id.contains("glow-layer") || layer.id.contains("symbol-layer") {
                    try mapView.mapboxMap.removeLayer(withId: layer.id)
                    print("🗑️ 레이어 제거 완료: \(layer.id)")
                }
            }
            
            let allSources = try mapView.mapboxMap.allSourceIdentifiers
            for source in allSources {
                if source.id.contains("source") {
                    try mapView.mapboxMap.removeSource(withId: source.id)
                    print("🗑️ 소스 제거 완료: \(source.id)")
                }
            }
        } catch {
            print("❌ 레이어 및 소스 제거 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 특정 CircleData만 업데이트
    func updateVideoCircleLayer(for circleData: CircleData) {
        print("👌 map 강제 업데이트중")
        let tileKey = circleData.tileKey
        let sourceId = "source-\(tileKey)"
        
        print("👌 map 강제 업데이트중 - TileKey: \(tileKey), Source ID: \(sourceId)")
        
        do {
            guard let tileInfo = tileService.getTileInfo(for: Tile.fromKey(tileKey)!) else {
                print("⚠️ \(tileKey)에 해당하는 타일 정보가 없습니다.")
                return
            }
            
            let currentTime = Date().timeIntervalSince1970 // 🔥 현재 시간 (초 단위)
            
            var features: [Feature] = []
            
            for item in tileInfo.layerData {
                var feature = Feature(geometry: .point(Point(item.location)))
                
                let encoder = JSONEncoder()
                if let encodedData = try? encoder.encode(item),
                   let jsonString = String(data: encodedData, encoding: .utf8) {
                    
                    // ✅ 남은 cooldown 계산 (0 이하이면 expired)
                    let elapsedTime = currentTime - (item.lastDropTime?.timeIntervalSince1970 ?? 0)
                    let remainingCooldown = max(item.cooldownTime - elapsedTime, 0)
                    
                    feature.properties = [
                        "circleData": .string(jsonString),
                        "genre": .string(item.genre.rawValue),
                        "rarity": .string(item.rarity.rawValue),
                        "remainingCooldown": .number(remainingCooldown) // ✅ 남은 시간 추가
                    ]
                }
                
                features.append(feature)
            }
            
            // ✅ 기존 GeoJSONSource 업데이트
            try mapView.mapboxMap.updateGeoJSONSource(
                withId: sourceId,
                geoJSON: .featureCollection(Turf.FeatureCollection(features: features))
            )
            print("🔄 특정 CircleData 업데이트 완료: \(circleData.id) on \(tileKey)")
            
        } catch {
            print("❌ 특정 CircleData 업데이트 실패: \(error.localizedDescription)")
        }
    }
}
