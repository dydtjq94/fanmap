//
//  MapView.swift
//  Storyworld
//
//  Created by peter on 1/7/25.
//

import SwiftUI

@main
struct StoryworldApp: App {
    @StateObject private var userService = UserService.shared
    @AppStorage("isUserInitialized") private var isUserInitialized = false
    @State private var isSplashScreenActive = true // 스플래시 상태

    var body: some Scene {
        WindowGroup {
            if isSplashScreenActive {
                SplashScreenView()
                    .onAppear {
                        loadData() // ✅ 앱 실행 시 데이터 로드 시작
                    }
            } else if isUserInitialized {
                ContentView()
                    .environmentObject(userService)
                    .transition(.opacity) // ✅ 부드러운 화면 전환 효과
            } else {
                StartView()
                    .transition(.opacity) // ✅ 부드러운 화면 전환 효과
            }
        }
    }

    private func loadData() {
        let splashMinimumDuration: TimeInterval = 2.0
        let startTime = Date() // ✅ 스플래시 시작 시간 기록

        DispatchQueue.main.async {
            userService.initializeUserIfNeeded()

            DispatchQueue.global(qos: .userInitiated).async {
                let userLoadedTime = Date() // ✅ 유저 데이터가 로드된 시간

                let elapsedTime = userLoadedTime.timeIntervalSince(startTime)
                let remainingTime = max(0, splashMinimumDuration - elapsedTime) // ✅ 최소 2초 보장

                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    if let user = userService.user {
                        isUserInitialized = user.nickname != "Guest"
                    } else {
                        isUserInitialized = false
                    }
                    isSplashScreenActive = false
                }
            }
        }
    }

}
