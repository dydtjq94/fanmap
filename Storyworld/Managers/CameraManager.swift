//
//  CameraManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import MapboxMaps
import CoreLocation

final class CameraManager {
    private let mapView: MapView
    private let defaultZoomLevel: Double
    
    // MARK: - Initializer
    init(mapView: MapView, defaultZoom: Double = Constants.Numbers.defaultZoomLevel) {
        self.mapView = mapView
        self.defaultZoomLevel = defaultZoom
    }
    
    // MARK: - Methods
    /// 초기 카메라 설정
    func setInitialCamera(to coordinate: CLLocationCoordinate2D) {
        let cameraOptions = CameraOptions(center: coordinate, zoom: defaultZoomLevel)
        mapView.mapboxMap.setCamera(to: cameraOptions)
        print("📍 초기 카메라가 위치로 설정되었습니다: \(coordinate.latitude), \(coordinate.longitude)")
    }
    
    /// 현재 위치로 카메라 이동
    func moveCameraToCurrentLocation(location: CLLocationCoordinate2D?, zoomLevel: Double = Constants.Numbers.defaultZoomLevel) {
        guard let location = location else {
            print("⚠️ 현재 위치 정보가 없습니다.")
            return
        }
        
        // 카메라 옵션 설정
        let cameraOptions = CameraOptions(center: location, zoom: zoomLevel)
        
        // 애니메이션을 사용하여 카메라 이동
        mapView.camera.ease(to: cameraOptions, duration: 0.2, curve: .easeInOut)
        
        print("📍 현재 위치로 카메라 이동 완료: \(location.latitude), \(location.longitude)")
    }
    
    /// 줌 설정
    func setZoomLevel(to zoomLevel: Double, duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        mapView.camera.ease(
            to: CameraOptions(zoom: zoomLevel),
            duration: duration,
            curve: .easeInOut
        ) { _ in
            print("✅ 줌 레벨이 \(zoomLevel)로 설정되었습니다.")
            completion?()
        }
    }
    
    /// 줌 인/줌 아웃
    func zoomIn(completion: (() -> Void)? = nil) {
        let currentZoom = mapView.mapboxMap.cameraState.zoom
        setZoomLevel(to: currentZoom + 1, completion: completion)
    }
    
    func zoomOut(completion: (() -> Void)? = nil) {
        let currentZoom = mapView.mapboxMap.cameraState.zoom
        setZoomLevel(to: currentZoom - 1, completion: completion)
    }
    
    func configureGestureOptions() {
        // 지도 기울이기 비활성화
        mapView.gestures.options.pitchEnabled = false // 기울이기 비활성화
        print("✅ 지도 기울이기가 비활성화되었습니다.")
    }
}
