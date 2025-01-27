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
    
    init(mapView: MapView) {
        self.mapView = mapView
    }
    
    func addGenreCircles(data: [MapCircleService.CircleData], userLocation: CLLocationCoordinate2D, isScan: Bool = false) {
        for (index, item) in data.enumerated() {
            let location = item.location
            
            // 타일 정보 기반 고유 ID 생성
            let tile = tileManager.calculateTile(for: location, zoomLevel: Int(Constants.Numbers.searchFixedZoomLevel))
            let tileKey = tile.toKey()
            
            let prefix = isScan ? "scan-\(UUID().uuidString)-" : ""
            let sourceId = "\(prefix)source-\(tileKey)"
            let glowLayerId = "\(prefix)glow-layer-\(tileKey)"
            let circleLayerId = "\(prefix)circle-layer-\(tileKey)"
            let symbolLayerId = "\(prefix)symbol-layer-\(tileKey)"
            
            // 드롭 여부에 따라 opacity 설정
            let opacityValue: Double = item.isRecentlyDropped() ? 0.3 : 1.0
            
            do {
                // GeoJSONSource 생성
                var feature = Feature(geometry: .point(Point(location)))
                feature.properties = [
                    "genre": .string(item.genre.rawValue),
                    "rarity": .string(item.rarity.rawValue),
                    "id": .string("\(index)")
                ]
                print("Adding Feature ID: \(item.genre.rawValue)-\(index)")
                var geoJSONSource = GeoJSONSource(id: sourceId)
                geoJSONSource.data = .feature(feature)
                
                // Source 추가
                try mapView.mapboxMap.addSource(geoJSONSource)
                
                // Glow Layer 설정
                if item.rarity == .diamond || item.rarity == .ruby {
                    var glowLayer = CircleLayer(id: glowLayerId, source: sourceId)
                    glowLayer.circleColor = .expression(
                        Exp(.match,
                            Exp(.get, "genre"),
                            VideoGenre.entertainment.rawValue, StyleColor(VideoGenre.entertainment.uiColor).rawValue,
                            VideoGenre.talk.rawValue, StyleColor(VideoGenre.talk.uiColor).rawValue,
                            VideoGenre.music.rawValue, StyleColor(VideoGenre.music.uiColor).rawValue,
                            VideoGenre.sports.rawValue, StyleColor(VideoGenre.sports.uiColor).rawValue,
                            VideoGenre.vlog.rawValue, StyleColor(VideoGenre.vlog.uiColor).rawValue,
                            VideoGenre.fashion.rawValue, StyleColor(VideoGenre.fashion.uiColor).rawValue,
                            VideoGenre.food.rawValue, StyleColor(VideoGenre.food.uiColor).rawValue,
                            VideoGenre.education.rawValue, StyleColor(VideoGenre.education.uiColor).rawValue,
                            VideoGenre.game.rawValue, StyleColor(VideoGenre.game.uiColor).rawValue,
                            StyleColor(UIColor.gray).rawValue // 기본값
                           )
                    )
                    glowLayer.circleRadius = .expression(
                        Exp(.match,
                            Exp(.get, "rarity"),
                            VideoRarity.diamond.rawValue, 30.0,
                            VideoRarity.ruby.rawValue, 50.0,
                            0.0 // 기본값
                           )
                    )
                    glowLayer.circleBlur = .constant(1.0)
                    glowLayer.circleOpacity = .constant(1.0)
                    
                    try mapView.mapboxMap.addLayer(glowLayer)
                }
                
                // Circle Layer 설정
                var circleLayer = CircleLayer(id: circleLayerId, source: sourceId)
                circleLayer.circleColor = .expression(
                    Exp(.match,
                        Exp(.get, "genre"),
                        VideoGenre.entertainment.rawValue, StyleColor(VideoGenre.entertainment.uiColor).rawValue,
                        VideoGenre.talk.rawValue, StyleColor(VideoGenre.talk.uiColor).rawValue,
                        VideoGenre.music.rawValue, StyleColor(VideoGenre.music.uiColor).rawValue,
                        VideoGenre.sports.rawValue, StyleColor(VideoGenre.sports.uiColor).rawValue,
                        VideoGenre.vlog.rawValue, StyleColor(VideoGenre.vlog.uiColor).rawValue,
                        VideoGenre.fashion.rawValue, StyleColor(VideoGenre.fashion.uiColor).rawValue,
                        VideoGenre.food.rawValue, StyleColor(VideoGenre.food.uiColor).rawValue,
                        VideoGenre.education.rawValue, StyleColor(VideoGenre.education.uiColor).rawValue,
                        VideoGenre.game.rawValue, StyleColor(VideoGenre.game.uiColor).rawValue,
                        StyleColor(UIColor.gray).rawValue // 기본값
                       )
                )
                circleLayer.circleRadius = .constant(14.0)
                circleLayer.circleOpacity = .constant(opacityValue)
                
                // Symbol Layer 설정
//                let sfSymbolName = "play.fill" // 사용할 SF Symbol 이름
//                let iconName = "sf-icon-play-fill" // Mapbox에서 사용할 고유 아이디
//                let mapVideoIconColor = AppColors.mapVideoIcon // UIColor
//                registerSFSymbol(mapView: mapView, iconName: iconName, sfSymbolName: sfSymbolName, color: mapVideoIconColor, size: 12)
//                
//                // Symbol Layer 설정
//                var symbolLayer = SymbolLayer(id: symbolLayerId, source: sourceId)
//                symbolLayer.iconImage = .constant(.name(iconName)) // 등록된 SF Symbol 아이디 사용
//                symbolLayer.iconSize = .constant(0.35) // 아이콘 크기 조정
//                symbolLayer.iconAnchor = .constant(.center) // 아이콘 위치
//                symbolLayer.iconAllowOverlap = .constant(true) // 중첩 허용
//                symbolLayer.iconIgnorePlacement = .constant(true) // 배치 무시
                
                // Mapbox 지도에 레이어 추가
                try mapView.mapboxMap.addLayer(circleLayer)
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
}
