import UIKit
import MapboxMaps
import CoreLocation
import Turf

final class ScanManager {
    private let mapView: MapView
    private let tileManager: TileManager
    private let tileService: TileService
    private let videoService: VideoService
    private let videoController: VideoController
    private var scanCircles: [UIView] = []
    private var isZooming = false
    
    init(mapView: MapView, tileManager: TileManager, tileService: TileService, videoService: VideoService, videoController: VideoController) {
        self.mapView = mapView
        self.tileManager = tileManager
        self.tileService = tileService
        self.videoService = videoService
        self.videoController = videoController
    }
    
    @objc func handleScanButtonTapped() {
        let firstZoom = Constants.Numbers.firstZoom
        let finalZoom = Constants.Numbers.finalZoom

        // 스캔 중에 Map과 Scan 버튼 비활성화
        mapView.isUserInteractionEnabled = false

        performZoom(to: firstZoom) { [weak self] in
            guard let self = self else { return }
            let centerCoordinate = self.mapView.mapboxMap.cameraState.center

            DispatchQueue.global(qos: .userInitiated).async {
                self.preloadTilesData(at: centerCoordinate)

                DispatchQueue.main.async {
                    self.startScanAnimation { [weak self] in
                        guard let self = self else { return }

                        // 미리 로드된 타일을 스캔 완료 후 한꺼번에 지도에 추가
                        self.addTilesToMap(self.preloadedTiles, coordinate: centerCoordinate, isScan: true)

                        print("✅ 모든 레이어가 성공적으로 추가되었습니다.")
                        
                        self.performZoom(to: finalZoom) {
                            print("✅ Zoom 레벨이 \(finalZoom)으로 복구되었습니다.")

                            // 스캔 완료 후 Map과 Scan 버튼 활성화
                            self.mapView.isUserInteractionEnabled = true
                        }
                    }
                }
            }
        }
    }
    
    private var preloadedTiles: [(Tile, [VideoService.CircleData])] = []
    
    private func preloadTilesData(at coordinate: CLLocationCoordinate2D) {
        print("📥 타일 데이터 미리 로드 시작: \(coordinate)")

        let visibleTiles = tileManager.tilesInRange(center: coordinate)
        print("📍 사전 로드할 타일 수: \(visibleTiles.count)개")

        preloadedTiles.removeAll()

        for tile in visibleTiles {
            if let tileInfo = tileService.getTileInfo(for: tile) {
                print("✔️ 이미 사전 로드된 타일: \(tile.toKey())")
                
                // isVisible 여부 상관없이 다시 추가할 리스트에 포함
                preloadedTiles.append((tile, tileInfo.layerData))
            } else {
                print("➕ 새로운 타일 발견: \(tile.toKey())")

                let newCircleData = videoService.createFilteredCircleData(visibleTiles: [tile], tileManager: tileManager)
                
                // 타일 정보를 저장 (isVisible을 false로 설정하여 후처리)
                tileService.saveTileInfo(for: tile, layerData: newCircleData, isVisible: false)

                preloadedTiles.append((tile, newCircleData))
            }
        }
    }

    private func addTilesToMap(_ tiles: [(Tile, [VideoService.CircleData])], coordinate: CLLocationCoordinate2D, isScan: Bool) {
        print("📊 즉시 타일 추가: \(tiles.count)개")

        for (tile, layerData) in tiles {
            if let tileInfo = tileService.getTileInfo(for: tile), tileInfo.isVisible {
                print("✔️ 이미 추가된 타일 건너뜀: \(tile.toKey())")
                continue
            }

            print("🟢 타일 즉시 추가: \(tile.toKey())")

            // 타일을 지도에 추가
            tileService.updateTileVisibility(for: tile, isVisible: true)
            videoController.videoLayerMapManager.addGenreCircles(
                data: layerData,
                userLocation: coordinate,
                isScan: isScan
            )
        }
    }
    
    private func startScanAnimation(completion: @escaping () -> Void) {
        let scanLineWidth: CGFloat = 4.0
        let scanDuration: TimeInterval = 2.0
        let fadeOutDelay: TimeInterval = 0.2  // 사라지기 전 대기 시간
        let mapWidth = mapView.frame.width

        let overlayView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: mapView.frame.height))
        overlayView.backgroundColor = UIColor.green.withAlphaComponent(0.1)
        mapView.addSubview(overlayView)

        let scanView = UIView(frame: CGRect(x: 0, y: 0, width: scanLineWidth, height: mapView.frame.height))
        scanView.backgroundColor = UIColor.green.withAlphaComponent(0.8)
        mapView.addSubview(scanView)

        // 스캔 애니메이션 실행
        UIView.animate(withDuration: scanDuration, delay: 0, options: .curveLinear, animations: {
            scanView.frame.origin.x = mapWidth
            overlayView.frame.size.width = mapWidth
        }, completion: { _ in
            // 딜레이 후 즉시 제거
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDelay) {
                overlayView.removeFromSuperview()
                scanView.removeFromSuperview()
                completion()
            }
        })
        
        addPulsingCirclesDuringScan(scanDuration: scanDuration)

        // 원 제거 작업도 일정 시간 후 실행
        DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.milliseconds(Int((scanDuration + fadeOutDelay) * 1000))) {
            self.removePulsingCirclesAfterScan()
        }
    }
    
    private func addPulsingCirclesDuringScan(scanDuration: TimeInterval) {
        let circleSize: CGFloat = 10.0
        let mapWidth = mapView.frame.width
        let mapHeight = mapView.frame.height
        
        let numberOfCircles = Int.random(in: 8...12)
        let genres = VideoGenre.allCases

        for _ in 0..<numberOfCircles {
            let randomXPosition = CGFloat.random(in: 0.1...0.9) * mapWidth
            let randomYPosition = CGFloat.random(in: 0.1...0.9) * mapHeight
            
            let randomGenre = genres.randomElement() ?? .entertainment
            let randomColor = randomGenre.uiColor
            
            let circleView = UIView(frame: CGRect(x: randomXPosition - circleSize / 2,
                                                  y: randomYPosition - circleSize / 2,
                                                  width: 0,
                                                  height: 0))
            circleView.layer.cornerRadius = circleSize / 2
            circleView.backgroundColor = randomColor
            circleView.alpha = 0.0
            mapView.addSubview(circleView)

            // 위치에 따른 정확한 시간 조정 (균일 속도로 움직이므로 정비례)
            let delay = (scanDuration * Double(randomXPosition / mapWidth))

            UIView.animate(withDuration: 0.3, delay: max(delay, 0), options: .curveEaseInOut, animations: {
                circleView.frame = CGRect(x: randomXPosition - circleSize / 2,
                                          y: randomYPosition - circleSize / 2,
                                          width: circleSize,
                                          height: circleSize)
                circleView.alpha = 1.0
            }, completion: nil)
            
            scanCircles.append(circleView)
        }
    }

    private func removePulsingCirclesAfterScan() {
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            for circle in self.scanCircles {
                circle.removeFromSuperview()
            }
            self.scanCircles.removeAll()
            print("⭕ 원이 제거되었습니다.")
        }
    }

    private func performZoom(to zoomLevel: Double, completion: @escaping () -> Void) {
        guard !isZooming else {
            print("⚠️ 줌 동작이 이미 진행 중입니다. 중복 호출 방지됨.")
            return
        }
        
        isZooming = true
        print("🔍 줌 시작: \(zoomLevel) 레벨로 이동 중...")

        mapView.camera.ease(to: CameraOptions(zoom: zoomLevel), duration: 0.7, curve: .easeInOut) { [weak self] position in
            guard let self = self else { return }

            if position == .end {
                print("✅ 줌 완료: \(zoomLevel)")
                self.isZooming = false
                completion()
            } else {
                print("❌ 줌 실패: \(zoomLevel) 재시도 중...")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isZooming = false  // 실패 시 플래그 해제
                    self.performZoom(to: zoomLevel, completion: completion)
                }
            }
        }
    }
}
