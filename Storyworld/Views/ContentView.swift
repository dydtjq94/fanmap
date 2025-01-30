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
            UITabBar.appearance().unselectedItemTintColor = UIColor(hex:"#434343")
            UITabBar.appearance().backgroundColor = UIColor(hex:"#1B1B1B")
            userService.initializeUserIfNeeded()  // 앱 시작 시 초기화
        }
        
        .onChange(of: selectedTab) {
            DispatchQueue.main.async {
                UIImpactFeedbackGenerator.trigger(.light)
            }
        }
    }
}
