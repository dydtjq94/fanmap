//
//  MapView.swift
//  Storyworld
//
//  Created by peter on 1/7/25.
//

import SwiftUI

@main
struct StoryworldApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var userService = UserService.shared
    @State private var isSplashScreenActive = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isSplashScreenActive {
                    SplashScreenView()
                        .transition(.opacity)
                        .onAppear {
                            loadData()
                        }
                } else if userService.user != nil {
                    ContentView()
                        .environmentObject(userService)
                        .transition(.opacity)
                } else {
                    StartView()
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.5), value: isSplashScreenActive) // ✅ 전환 애니메이션 추가
        }
    }

    private func loadData() {
        let splashMinimumDuration: TimeInterval = 1.5
        let startTime = Date()

        DispatchQueue.main.async {
            userService.initializeUserIfNeeded()

            DispatchQueue.global(qos: .userInitiated).async {
                let elapsedTime = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, splashMinimumDuration - elapsedTime)

                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    withAnimation { // ✅ 애니메이션을 추가하여 부드럽게 전환
                        isSplashScreenActive = false
                    }
                }
            }
        }
    }
}
