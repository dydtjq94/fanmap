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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userService)  // environment에 올바르게 주입
        }
    }
}
