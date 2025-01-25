//
//  DropManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import UIKit
import MapboxMaps

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
    
    func showProSubscriptionMessage() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        print("🔒 PRO 구독이 필요합니다.")
        // PRO 구독 안내 화면을 추가로 구현 가능
    }
    
    func showAdMessage() {
        let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
        feedbackGenerator.prepare()
        feedbackGenerator.impactOccurred()
        print("📢 광고 보기가 필요합니다.")
        // 광고 보기 화면을 추가로 구현 가능
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
