//
//  ViewController.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import UIKit
import MapboxMaps
import CoreLocation
import Turf

final class ViewController: UIViewController, CLLocationManagerDelegate {
    private var mapView: MapView!
    private var videoLayerMapManager: VideoLayerMapManager!
    private let locationManager = CLLocationManager()
    private let mapCircleService = MapCircleService()
    private var videoController: VideoController?
    private let tileManager = TileManager()
    private let tileService = TileService()
    private let locationCircleManager = LocationCircleManager()
    private var notificationManager: NotificationManager? // NotificationManager 추가
    private var cameraManager: CameraManager? // CameraManager 추가
    private var mapStyleManager: MapStyleManager? // StyleManager 추가
    private var scanManager: ScanManager?
    
    private var lastBackgroundTime: Date? // 마지막 백그라운드 전환 시각
    
    private var isLocationPermissionHandled = false // 권한 처리 여부 확인 변수
    private var isVideoDataLoaded = false // 영화 데이터 로드 여부 추가
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMapView()
        setupLocationManager()
        videoLayerMapManager = VideoLayerMapManager(mapView: mapView)

        scanManager = ScanManager(
            mapView: mapView,
            tileManager: tileManager,
            tileService: tileService,
            mapCircleService: mapCircleService,
            videoController: videoController!,
            videoLayerMapManager: videoLayerMapManager
        )
        
        // NotificationManager 초기화
        notificationManager = NotificationManager(
            onScanButtonTapped: { [weak self] in
                self?.scanManager?.handleScanButtonTapped()
            },
            onAppWillEnterForeground: { [weak self] in
                self?.handleAppWillEnterForeground()
            },
            onAppDidEnterBackground: { [weak self] in
                self?.handleAppDidEnterBackground()
            },
            onLocationButtonTapped: { [weak self] in
                self?.moveCameraToCurrentLocation()
            }
        )
        notificationManager?.setupNotifications()
        
        // 스타일 설정 및 카메라 제스처 옵션 설정
        mapStyleManager?.applyDarkStyle {
            print("✅ 스타일 설정 후 카메라 제스처 옵션을 적용합니다.")
            self.cameraManager?.configureGestureOptions() // cameraManager에서 제스처 옵션 설정
        }
    }
    
    // MARK: - MapView 설정
    private func setupMapView() {
        // ✅ Info.plist에서 AccessToken 가져오기
        guard Bundle.main.object(forInfoDictionaryKey: "MBXAccessToken") is String else {
            fatalError("❌ Mapbox Access Token이 Info.plist에 설정되지 않았습니다.")
        }
        
        // ✅ MapInitOptions 초기화
        let mapInitOptions = MapInitOptions(
            cameraOptions: CameraOptions(zoom: Constants.Numbers.defaultZoomLevel),
            styleURI: .dark // 🌙 다크 모드 적용
        )
        
        // ✅ MapView 설정
        mapView = MapView(frame: view.bounds, mapInitOptions: mapInitOptions)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        // ✅사용자 위치 표시 설정
        configureUserLocationDisplay()
        
        // ✅ CameraManager와 StyleManager 초기화
        cameraManager = CameraManager(mapView: mapView)
        mapStyleManager = MapStyleManager(mapView: mapView)
        
        // ✅ VideoController 초기화
        videoController = VideoController(mapView: mapView)
        
        handleStyleLoadedEvent()
        
        // ✅ MapView를 뷰에 추가
        view.addSubview(mapView)
    }

    
    @objc private func handleAppWillEnterForeground() {
        guard let lastBackgroundTime = lastBackgroundTime else { return }
        
        let timeInBackground = Date().timeIntervalSince(lastBackgroundTime)
        
        if timeInBackground > Constants.Numbers.backgroundLongTimer {
            // 1시간 이상 백그라운드에 있었다면 초기 상태로 복원
            print("🔄 앱이 \(timeInBackground)초 이상 백그라운드에 있었습니다. 초기 상태로 복원합니다.")
            
            // 사용자 위치 가져오기
            guard let coordinate = mapView.location.latestLocation?.coordinate else {
                print("⚠️ 현재 위치 정보를 가져올 수 없습니다.")
                return
            }
            
            videoLayerMapManager.removeAllVideoLayers()
            locationCircleManager.addCircleLayers(to: mapView, at: coordinate)
            moveCameraToCurrentLocation()
            // 캐시된 타일 데이터 초기화 (선택 사항)
            tileService.resetTileVisibility()
            
            // 타일 데이터 로드 및 Circle 레이어 추가
            loadTilesAndAddCircles(at: coordinate)
            
            reloadLocationPuck()
            
        } else if timeInBackground > Constants.Numbers.backgroundTimer { // 예: 30초
            // 30초 이상 백그라운드에 있었다면 현재 위치로 이동 및 데이터 갱신
            print("🔄 앱이 \(timeInBackground)초 이상 백그라운드에 있었습니다. 현재 위치로 화면 이동.")
            moveCameraToCurrentLocation()
            
            // 사용자 위치 가져오기
            guard let coordinate = mapView.location.latestLocation?.coordinate else {
                print("⚠️ 현재 위치 정보를 가져올 수 없습니다.")
                return
            }
            
            // 타일 데이터 로드 및 Circle 레이어 추가
            loadTilesAndAddCircles(at: coordinate)
            
            reloadLocationPuck()
        } else {
            print("⏳ 앱이 \(timeInBackground)초 동안 백그라운드에 있었습니다. 업데이트 필요 없음.")
        }
    }
    
    // MARK: - 앱이 백그라운드로 전환될 때
    @objc private func handleAppDidEnterBackground() {
        lastBackgroundTime = Date() // 백그라운드 전환 시각 저장
        print("🔄 앱이 백그라운드로 전환되었습니다.")
    }
    
    // MARK: - 현재 위치로 화면 이동
    private func moveCameraToCurrentLocation(zoomLevel: Double = Constants.Numbers.defaultZoomLevel) {
        guard let userLocation = mapView.location.latestLocation?.coordinate else {
            print("❌ 사용자 위치를 가져올 수 없습니다.")
            return
        }
        cameraManager?.moveCameraToCurrentLocation(location: userLocation, zoomLevel: zoomLevel)
    }
    
    private func configureUserLocationDisplay() {
        // ✅ 사용자 위치 표시 (화살표 포함)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        print("✅ 사용자 위치 표시 설정 완료")
    }
    
    private var styleLoadedCancelable: AnyCancelable? // Cancelable 객체 저장용 변수
    
    private func handleStyleLoadedEvent() {
        styleLoadedCancelable = mapView.mapboxMap.onStyleLoaded.observe { [weak self] _ in
            guard let self = self else { return }

            let coordinate = self.mapView.location.latestLocation?.coordinate
            ?? CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780) // 기본 위치

            self.cameraManager?.setInitialCamera(to: coordinate)
            self.locationCircleManager.addCircleLayers(to: self.mapView, at: coordinate)
            self.loadTilesAndAddCircles(at: coordinate)
            self.mapStyleManager?.applyDarkStyle()
            self.reloadLocationPuck()
        }
    }
    
    /// 여러 타일을 한 번에 저장하는 새로운 함수
    private func batchSaveTileInfo(tiles: [Tile], coordinate: CLLocationCoordinate2D, isScan: Bool) -> [Tile: [MapCircleService.CircleData]] {
        var newTileInfoDict: [Tile: [MapCircleService.CircleData]] = [:]
        
        for tile in tiles {
            let newCircleData = mapCircleService.createFilteredCircleData(visibleTiles: [tile], tileManager: tileManager)
            newTileInfoDict[tile] = newCircleData
        }

        tileService.saveMultipleTileInfo(tileInfoDict: newTileInfoDict, isVisible: true)
        return newTileInfoDict // 저장된 타일 데이터를 리턴
    }

    /// 최적화된 타일 로드 및 추가 함수
    func loadTilesAndAddCircles(at coordinate: CLLocationCoordinate2D, isScan: Bool = false) {
        let visibleTiles = tileManager.tilesInRange(center: coordinate)
        print("📍 현재 보이는 타일: \(visibleTiles.count)개")

        guard let videoController = self.videoController else {
            print("⚠️ VideoController가 초기화되지 않았습니다.")
            return
        }
        
        var tilesToUpdate: [Tile] = []
        var newTiles: [Tile] = []
        var circlesToAdd: [(Tile, [MapCircleService.CircleData])] = []

        for tile in visibleTiles {
            if let tileInfo = tileService.getTileInfo(for: tile) {
                print("🔍 가시성 업데이트 대상 타일: \(tile.toKey()), isVisible: \(tileInfo.isVisible)")
                 
                if tileInfo.isVisible {
                    print("✔️ 이미 추가된 타일: \(tile.toKey()), 건너뛰기")
                    continue
                } else {
                    print("🔄 기존 타일 가시성 업데이트 필요: \(tile.toKey())")
                    tilesToUpdate.append(tile)
                    circlesToAdd.append((tile, tileInfo.layerData)) // 기존 타일 레이어 추가
                }
            } else {
                print("➕ 새로운 타일 발견: \(tile.toKey())")
                newTiles.append(tile)
            }
        }

        // 가시성 업데이트를 한 번에 처리
        if !tilesToUpdate.isEmpty {
            print("📝 가시성 업데이트를 시도할 타일 목록: \(tilesToUpdate.map { $0.toKey() })")
            tileService.batchUpdateTileVisibility(tiles: tilesToUpdate, isVisible: true)
        }

        // 새로운 타일들을 한 번에 저장 후 그리기
        if !newTiles.isEmpty {
            let newTileDataDict = batchSaveTileInfo(tiles: newTiles, coordinate: coordinate, isScan: isScan)
            for (tile, circleData) in newTileDataDict {
                circlesToAdd.append((tile, circleData))
            }
        }

        // 지도에 모든 타일의 레이어 추가 (기존 + 새로운 타일 포함)
        for (tile, circleData) in circlesToAdd {
            videoController.videoLayerMapManager.addGenreCircles(
                data: circleData,
                userLocation: coordinate,
                isScan: isScan
            )
            print("🎨 타일 레이어 추가 완료: \(tile.toKey())")
        }
    }

    
    private func reloadLocationPuck() {
        // 현재 Puck을 비활성화
        mapView.location.options.puckType = nil
        print("✅ Puck 비활성화 완료")
        
        // Puck 다시 활성화 (레이어 재배치)
        mapView.location.options.puckType = .puck2D(Puck2DConfiguration.makeDefault(showBearing: true))
        mapView.location.options.puckBearingEnabled = true
        mapView.location.options.puckBearing = .heading
        print("✅ Puck 다시 활성화 완료")
    }
    
    // MARK: - 사용자 위치 업데이트
    private var lastUpdatedLocation: CLLocation?
    private let minimumDistanceThreshold: CLLocationDistance = 5 // 10m 이상 이동 시 업데이트
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 5 // 하드웨어 필터링 (5m)
        locationManager.startUpdatingLocation()
    }
    
    // 위치 권한 변경 시 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard !isLocationPermissionHandled else { return }
        isLocationPermissionHandled = true
        
        let status = manager.authorizationStatus
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("✅ 위치 권한 허용됨.")
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            print("❌ 위치 권한 거부됨.")
            moveCameraToCurrentLocation()
        case .notDetermined:
            print("❓ 위치 권한 결정되지 않음.")
        @unknown default:
            print("⚠️ 알 수 없는 위치 권한 상태.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.last else { return }
        
        if let lastLocation = lastUpdatedLocation {
            let distance = userLocation.distance(from: lastLocation)
            print("📏 이동 거리: \(String(format: "%.2f", distance))m")
            
            if distance < minimumDistanceThreshold {
                print("⚠️ 위치 변화가 미미함, 업데이트 생략")
                return
            }
        }
        
        locationCircleManager.updateCircleLayers(for: mapView, at: userLocation.coordinate)
        lastUpdatedLocation = userLocation
        print("📍 사용자 위치 업데이트됨 - 원만 업데이트됨, 화면 유지")
    }
}
