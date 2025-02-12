//
//  ProfileTab.swift
//  Storyworld
//
//  Created by peter on 1/8/25.
//

import SwiftUI

struct ProfileTab: View {
    @EnvironmentObject var userService: UserService
    @State private var showingSettings = false // 설정 시트 표시 여부를 관리하는 상태 변수

    init() {
        // 🔥 네비게이션 바의 Appearance 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground() // 투명 배경 제거
        appearance.backgroundColor = UIColor(hex: "#1D1D1D") // 원하는 색상 적용
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // 타이틀 색상 설정
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white] // 큰 타이틀 색상 설정
        
        // 네비게이션 바에 Appearance 적용
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // 유저 프로필 섹션
                if userService.user != nil {
                    UserProfileView()
                } else {
                    ProgressView("Loading...")
                }
                
                // 플레이리스트 섹션
                PlaylistView()
                
                // 컬렉션 섹션
                CollectionView()
            }
            .padding(.horizontal, 16) // 좌우 패딩 적용
            .padding(.bottom, 32) // 하단 패딩 적용
            .padding(.top, 16)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    UIImpactFeedbackGenerator.trigger(.light)
                    showingSettings.toggle()
                }) {
                    Image(systemName: "gearshape") // 설정 아이콘
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView() // 설정 시트로 표시할 뷰
        }
        .refreshable {
            userService.initializeUserIfNeeded()
        }
        .background(Color(UIColor(hex:"#121212")))
    }
}
