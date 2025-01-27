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
    
    
    init(mapView: MapView) {
        self.mapView = mapView
    }
    
    func displayVideoDetails(video: Video) {
        print("🎥 Video Details:")
        print("🎬 Title: \(video.title)")
        print("🎭 Genre: \(video.genre.rawValue)")
        print("🌟 Rarity: \(video.rarity.rawValue)")
        // UI 업데이트 로직 추가 가능 (예: 포스터, 제목, 즐겨찾기 버튼 표시)
    }
    
    func showProSubscriptionView(videoGenre: VideoGenre, videoRarity: VideoRarity) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        print("🔒 PRO 구독이 필요합니다.")
        
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = scene.windows.first,
           let topVC = window.rootViewController {
            
            let proView = ProSubscriptionView()
            let hostingController = UIHostingController(rootView: proView)
            hostingController.modalPresentationStyle = .overFullScreen
            topVC.present(hostingController, animated: true, completion: nil)
        }
    }
    
    func showDropWithCachView(videoGenre: VideoGenre, videoRarity: VideoRarity) {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        // 최상위 ViewController 찾기
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first,
              let topVC = window.rootViewController {
               
               let proView = DropWithCoinView(genre: videoGenre, rarity: videoRarity)
               let hostingController = UIHostingController(rootView: proView)

               // 배경을 투명하게 설정
               hostingController.view.backgroundColor = UIColor.clear
               hostingController.modalPresentationStyle = .overFullScreen
               
               topVC.present(hostingController, animated: true, completion: nil)
           }
    }
    
    func handleDropWithinDefault(videoGenre: VideoGenre, videoRarity: VideoRarity) {
        print("🎯 클릭된 Circle - Genre: \(videoGenre.rawValue), Rarity: \(videoRarity.rawValue)")
        
        // 햅틱 피드백 생성
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        
        // DropController 호출 (API 없이)
        presentDropController(genre: videoGenre, rarity: videoRarity)
    }
    
    func presentDropController(genre: VideoGenre, rarity: VideoRarity) {
        let dropController = DropController(genre: genre, rarity: rarity)
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
