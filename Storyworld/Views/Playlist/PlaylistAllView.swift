import SwiftUI

struct PlaylistAllView: View {
    @Environment(\.isPresented) private var isPresented
    @State private var tabBarVisible: Bool = false
    @StateObject private var viewModel = PlaylistViewModel()
    @StateObject private var sheetManager = SheetManager()
    @State private var showAddPlaylistAlert = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        ScrollView {
            if viewModel.playlists.isEmpty {
                VStack {
                    Spacer()
                    Text("아직 만든 플레이리스트가 없어요!")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.top, 100)
                    Spacer()
                }
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.playlists, id: \.id) { playlist in
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            sheetManager.presentPlaylistDetail(for: playlist)
                        }) {
                            PlaylistItemView(playlist: playlist)
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Color(UIColor(hex:"#1D1D1D")))
        .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
        .onChange(of: isPresented) {
            if !isPresented {
                self.tabBarVisible = true
            }
        }
        .onAppear {
            if viewModel.playlists.isEmpty { // ✅ 초기 값 확인 후 로드
                viewModel.loadPlaylists()
            }
        }
        .sheet(isPresented: $sheetManager.showPlaylistDetail, onDismiss: {
            print("플레이리스트 상세 화면 닫힘, 데이터 새로고침")
            viewModel.loadPlaylists()

            // ✅ 로컬 캐시된 이미지 강제 갱신
            for playlist in viewModel.playlists {
                if let updatedImage = PlaylistService.shared.loadPlaylistImageLocally(playlist.id) {
                    NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistID": playlist.id, "image": updatedImage])
                }
            }
        }){
            if let playlist = sheetManager.selectedPlaylist {
                PlaylistDetailedView(
                    playlist: playlist,
                    playlistViewModel: viewModel,
                    sheetManager: sheetManager  // 여기 추가
                )
            }
        }
        .overlay(
            VStack {
                Spacer() // 상단 공간 확보
                HStack {
                    Spacer() // 좌측 공간 확보
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        showAddPlaylistAlert = true
                    }) {
                        Text("재생 목록 추가")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.black)
                            .frame(width: 180, height: 48)
                            .background(Color(AppColors.mainColor))
                            .cornerRadius(32)
                            .shadow(radius: 4)
                            .shadow(color: Color(AppColors.mainColor).opacity(0.3), radius: 10, x: 0, y: 0)
                    }
                    Spacer() // 우측 공간 확보
                }
                .padding(.bottom, 20)  // 하단 여백 조정
            }
        )
        .onAppear {
            DispatchQueue.main.async {
                updateNewPlaylistName()
            }
        }
        .alert("새 재생 목록 추가", isPresented: $showAddPlaylistAlert) {
            VStack {
                TextField("재생 목록 이름", text: $newPlaylistName)
                HStack {
                    Button("취소", role: .cancel) {
                        UIImpactFeedbackGenerator.trigger(.light)
                        showAddPlaylistAlert = false
                    }
                    Button("추가") {
                        UIImpactFeedbackGenerator.trigger(.light)
                        Task {
                            if let newPlaylist = await PlaylistService.shared.createNewPlaylist(name: newPlaylistName) {
                                DispatchQueue.main.async {
                                    showAddPlaylistAlert = false
                                    viewModel.loadPlaylists() // ✅ 최신 데이터 불러오기
                                    sheetManager.presentPlaylistDetail(for: newPlaylist) // ✅ 디테일 뷰 표시
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateNewPlaylistName() {
        let playlistCount = PlaylistService.shared.loadPlaylists().count + 1
        newPlaylistName = "새 재생 목록 #\(playlistCount)"
    }
}
