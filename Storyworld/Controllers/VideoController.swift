//
//  VideoController.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import UIKit
import MapboxMaps
import Turf

final class VideoController {
    private let mapView: MapView
    let videoLayerMapManager: VideoLayerMapManager
    private var gestureManager: GestureManager!
    private var selectedVideo: Video?
    private let dropManager: DropManager
    
    init(mapView: MapView, video: Video? = nil) {
        self.mapView = mapView
        self.selectedVideo = video
        self.videoLayerMapManager = VideoLayerMapManager(mapView: mapView)
        self.dropManager = DropManager(mapView: mapView)
        self.gestureManager = GestureManager(
            mapView: mapView,
            onFeatureSelected: { [weak self] feature in
                self?.handleFeatureSelection(feature)
            }
        )
    }
    
    func updateUIWithVideoData() {
        guard let video = selectedVideo else { return }
    }
    
    // Feature 선택 처리
    private func handleFeatureSelection(_ feature: Feature) {
        guard case let .point(pointGeometry) = feature.geometry else {
            print("⚠️ Feature의 좌표를 가져올 수 없습니다.")
            return
        }
        
        let coordinates = pointGeometry.coordinates
        
        print("🔍 Feature Properties: \(feature.properties ?? [:])") // ✅ 디버깅 추가
        
        guard let circleDataValue = feature.properties?["circleData"],
              case let .string(encodedCircleData) = circleDataValue,
              let circleData = decodeCircleData(from: encodedCircleData) else {
            print("⚠️ Feature 속성에서 CircleData를 추출할 수 없습니다.")
            return
        }
        
        print("circledata: \(circleData)")
        
        guard let userLocation = mapView.location.latestLocation?.coordinate else {
            print("⚠️ 사용자 위치를 가져올 수 없습니다.")
            return
        }
        
        // 거리 계산
        let circleLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let userLocationCL = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        let distance = userLocationCL.distance(from: circleLocation)
        
        print("📍 Distance from user: \(distance) meters")
        
        if distance <= Constants.Numbers.smallCircleRadius {
            // 50m 이내 Drop 처리
            dropManager.handleDropWithinDefault(circleData: circleData)
        } else if distance <= Constants.Numbers.largeCircleRadius {
            // 200m 이내 pro 구매 메시지 표시
//            dropManager.showProSubscriptionView(circleData: circleData)
        } else {
            // 200m 이상 광고 메시지 표시
            dropManager.showDropWithCoinView(circleData: circleData)
//            dropManager.handleDropWithinDefault(circleData: circleData)
        }
    }
    
    func decodeCircleData(from jsonString: String) -> MapCircleService.CircleData? {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase // ✅ 변환된 값이 올바르게 매핑되도록 설정

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ JSON 변환 실패: \(jsonString)")
            return nil
        }
        
        do {
            let decodedData = try decoder.decode(MapCircleService.CircleData.self, from: jsonData)
            print("✅ 디코딩 성공: \(decodedData)")
            return decodedData
        } catch {
            print("❌ CircleData 디코딩 실패: \(error.localizedDescription)")
            return nil
        }
    }
}
