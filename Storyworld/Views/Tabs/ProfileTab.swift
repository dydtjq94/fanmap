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
    @StateObject private var playlistViewModel = PlaylistViewModel()
    @StateObject private var collectionViewModel = CollectionViewModel()

    init() {
        // 🔥 네비게이션 바의 Appearance 설정
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(hex: "#1D1D1D")
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                
                // ✅ 유저 프로필 섹션
                if userService.user != nil {
                    UserProfileView()
                } else {
                    ProgressView("Loading...")
                }

                // ✅ 플레이리스트 섹션
                PlaylistView(viewModel: playlistViewModel)

                // ✅ 컬렉션 섹션
                CollectionView(viewModel: collectionViewModel)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 32)
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
            SettingsView()
        }
        .refreshable {
            Task {
                userService.initializeUserIfNeeded() // ✅ 유저 데이터
                DispatchQueue.main.async {
                    playlistViewModel.loadPlaylists() // ✅ UI 업데이트
                    collectionViewModel.loadVideos() // ✅ UI 업데이트
                }
            }
        }
        .background(Color(UIColor(hex:"#121212")))
    }
}
