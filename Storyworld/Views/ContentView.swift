//
//  ContentView.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var userService = UserService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationView {
                MapTab()
            }
            .tabItem {
                Label("Map", systemImage: "map")
            }
            .tag(0)
            .tint(.gray)
            
            NavigationView {
               ProfileTab()
            }
            .tabItem {
                Label("Profile", systemImage: "person")
            }
            .tag(1)

        }
        .environmentObject(userService)  // 하위 뷰에 전달
        .tint(Color.white)
        .onAppear {
            let tabBarAppearance = UITabBarAppearance()
            tabBarAppearance.backgroundColor = UIColor(hex: "#1B1B1B") // ✅ 원하는 색상 고정
            tabBarAppearance.shadowColor = .clear // ✅ 하단 경계선 제거

            UITabBar.appearance().standardAppearance = tabBarAppearance
            UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
            UITabBar.appearance().unselectedItemTintColor = UIColor(hex: "#434343") // ✅ 비활성화 아이콘 색
            UITabBar.appearance().tintColor = .white // ✅ 활성화 아이콘 색
            
            userService.initializeUserIfNeeded()
        }
        
        .onChange(of: selectedTab) {
            DispatchQueue.main.async {
                UIImpactFeedbackGenerator.trigger(.light)
            }
        }
    }
}
