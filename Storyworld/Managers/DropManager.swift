//
//  DropManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import UIKit
import MapboxMaps
import SwiftUI

final class DropManager {
    private let mapView: MapView
    private let cameraManager: CameraManager  // 🔥 추가
    
    
    init(mapView: MapView) {
        self.mapView = mapView
        self.cameraManager = CameraManager(mapView: mapView) // ✅ CameraManager 초기화
            }
//
//    func showProSubscriptionView(videoGenre: VideoGenre, videoRarity: VideoRarity) {
//        UIImpactFeedbackGenerator.trigger(.heavy)
//        
//        print("🔒 PRO 구독이 필요합니다.")
//        
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//           let window = scene.windows.first,
//           let topVC = window.rootViewController {
//            
//            let proView = ProSubscriptionView()
//            let hostingController = UIHostingController(rootView: proView)
//            hostingController.modalPresentationStyle = .overFullScreen
//            topVC.present(hostingController, animated: true, completion: nil)
//        }
//    }
    
    func showDropWithCoinView(circleData: CircleData) {
        UIImpactFeedbackGenerator.trigger(.heavy)
        
        // ✅ 현재 카메라의 줌 레벨 가져오기
           let currentZoom = mapView.mapboxMap.cameraState.zoom
        
        // ✅ 카메라를 해당 CircleData 위치로 이동
        cameraManager.moveCameraToCurrentLocation(location: circleData.location, zoomLevel: currentZoom)

        
        // 최상위 ViewController 찾기
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let topVC = window.rootViewController {
               
               let proView = DropWithCoinView(circleData: circleData)
               let hostingController = UIHostingController(rootView: proView)

               // 배경을 투명하게 설정
               hostingController.view.backgroundColor = UIColor.clear
               hostingController.modalPresentationStyle = .overFullScreen
               
               topVC.present(hostingController, animated: true, completion: nil)
           }
    }
    
    func handleDropWithinDefault(circleData: CircleData) {
        print("🎯 클릭된 Circle - \(circleData)")
        
        // 남은 쿨다운 계산
        let currentTime = Date().timeIntervalSince1970
        let elapsedTime = currentTime - (circleData.lastDropTime?.timeIntervalSince1970 ?? 0)
        let remainingCooldown = max(circleData.cooldownTime - elapsedTime, 0)
        
        if remainingCooldown > 0 {
            // 쿨다운 중이면 DropWithCoinView를 보여줌
            print("⏳ 쿨다운 중 - 남은 시간: \(remainingCooldown)초")
            showDropWithCoinView(circleData: circleData)
        } else {
            // 쿨다운이 끝났으면 DropController를 보여줌
            print("✅ 쿨다운 종료 - 드롭 가능")
            UIImpactFeedbackGenerator.trigger(.heavy)
            presentDropController(circleData: circleData)
        }
    }
    
    func presentDropController(circleData: CircleData) {
        let dropController = DropController(circleData: circleData, mapView: mapView)
        dropController.modalPresentationStyle = .overFullScreen
        dropController.modalTransitionStyle = .coverVertical
        mapView.window?.rootViewController?.present(dropController, animated: true, completion: nil)
    }
    
    func showErrorMessage(_ message: String) {
        guard let rootVC = mapView.window?.rootViewController else { return }
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        rootVC.present(alert, animated: true, completion: nil)
    }
}
