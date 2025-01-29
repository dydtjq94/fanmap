//
//  NotificationManager.swift
//  Storyworld
//
//  Created by peter on 1/15/25.
//

import UIKit

final class NotificationManager: NSObject {
    // MARK: - Properties
    private var handleScanButton: (() -> Void)?
    private var handleLocationButton: (() -> Void)?
    private var handleAppForeground: (() -> Void)?
    private var handleAppBackground: (() -> Void)?
    private var handleScanCompleted: (() -> Void)? // ✅ Scan 완료 핸들러 추가
    
    // MARK: - Initializer
    init(
        onScanButtonTapped: @escaping () -> Void,
        onAppWillEnterForeground: @escaping () -> Void,
        onAppDidEnterBackground: @escaping () -> Void,
        onLocationButtonTapped: @escaping () -> Void,
        onScanCompleted: @escaping () -> Void // ✅ Scan 완료 핸들러 추가
    ) {
        self.handleScanButton = onScanButtonTapped
        self.handleAppForeground = onAppWillEnterForeground
        self.handleAppBackground = onAppDidEnterBackground
        self.handleLocationButton = onLocationButtonTapped
        self.handleScanCompleted = onScanCompleted // ✅ 추가
    }
    
    // MARK: - Setup Notifications
    func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScanButtonTapped),
            name: .scanButtonTapped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleLocationButtonTapped),
            name: .locationButtonTapped,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleScanCompletedStatus),
            name: .scanCompleted,
            object: nil
        ) // ✅ Scan 완료 감지 추가
    }
    
    // MARK: - Notification Handlers
    @objc private func handleScanButtonTapped() {
        print("🔄 Scan 버튼이 눌렸습니다.")
        handleScanButton?()
    }
    
    // 내 위치 버튼 핸들러 추가
    @objc private func handleLocationButtonTapped() {
        print("📍 내 위치 버튼 클릭됨")
        handleLocationButton?()
    }
    
    @objc private func handleAppWillEnterForeground() {
        print("🔄 앱이 포그라운드로 돌아왔습니다.")
        handleAppForeground?()
    }
    
    @objc private func handleAppDidEnterBackground() {
        print("🔄 앱이 백그라운드로 전환되었습니다.")
        handleAppBackground?()
    }
    
    @objc private func handleScanCompletedStatus() { // ✅ Scan 완료 핸들러
        print("✅ Scan 완료 - Puck 리로드 실행")
        handleScanCompleted?()
    }
    
    // MARK: - Deinit
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
