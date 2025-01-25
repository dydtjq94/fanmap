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
        dropManager.displayVideoDetails(video: video)
    }
    
    // Feature 선택 처리
    private func handleFeatureSelection(_ feature: Feature) {
        guard case let .point(pointGeometry) = feature.geometry else {
            print("⚠️ Feature의 좌표를 가져올 수 없습니다.")
            return
        }
        
        let coordinates = pointGeometry.coordinates
        
        guard let genreValue = feature.properties?["genre"],
              case let .string(genre) = genreValue,
              let rarityValue = feature.properties?["rarity"],
              case let .string(rarity) = rarityValue else {
            print("⚠️ Feature 속성에서 데이터를 추출할 수 없습니다.")
            return
        }
        
        guard let videoGenre = VideoGenre(rawValue: genre) else {
            print("⚠️ 잘못된 장르 데이터입니다.")
            return
        }
        
        guard let videoRarity = VideoRarity(rawValue: rarity) else {
            print("⚠️ 잘못된 등급 데이터입니다.")
            return
        }
        
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
            handleDropWithin50m(videoGenre: videoGenre, videoRarity: videoRarity)
        } else if distance <= Constants.Numbers.largeCircleRadius {
            // 200m 이내 Pro 구독 메시지 표시
            //            dropManager.showProSubscriptionMessage()
            handleDropWithin50m(videoGenre: videoGenre, videoRarity: videoRarity)
        } else {
            // 200m 이상 광고 메시지 표시
            //            dropManager.showAdMessage()
            handleDropWithin50m(videoGenre: videoGenre, videoRarity: videoRarity)
        }
    }
    
    // 50m 이내 Drop 처리
    private func handleDropWithin50m(videoGenre: VideoGenre, videoRarity: VideoRarity) {
        print("🎯 클릭된 Circle - Genre: \(videoGenre.rawValue), Rarity: \(videoRarity.rawValue)")
        
        // 햅틱 피드백 생성
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        // DropController 호출 (API 없이)
        dropManager.presentDropController(genre: videoGenre, rarity: videoRarity)
    }
}
