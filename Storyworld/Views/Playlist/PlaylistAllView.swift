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
            LazyVStack(spacing: 12) {
                ForEach(viewModel.playlists, id: \.id) { playlist in
                    Button(action: {
                        sheetManager.presentPlaylistDetail(for: playlist)
                    }) {
                        PlaylistItemView(playlist: playlist)
                    }
                }
                Spacer() // 빈 공간에서도 스크롤 가능하게 확장
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .background(Color(UIColor(hex:"#1D1D1D")))
        .toolbar(tabBarVisible ? .visible : .hidden, for: .tabBar)
        .onChange(of: isPresented) {
            if !isPresented {
                self.tabBarVisible = true
            }
        }
        .onAppear {
            viewModel.loadPlaylists()
        }
        .sheet(isPresented: $sheetManager.showPlaylistDetail, onDismiss: {
            print("Playlist sheet dismissed. Reloading playlists...")
            viewModel.loadPlaylists()
        }) {
            if let playlist = sheetManager.selectedPlaylist {
                PlaylistDetailedView(
                    playlist: playlist,
                    playlistViewModel: viewModel,
                    sheetManager: sheetManager
                )
            }
        }
        .overlay(
            VStack {
                Spacer() // 상단 공간 확보
                HStack {
                    Spacer() // 좌측 공간 확보
                    Button(action: {
                        showAddPlaylistAlert = true
                    }) {
                        Text("재생 목록 추가")
                            .font(.headline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(24)
                            .shadow(radius: 5)
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
                        showAddPlaylistAlert = false
                    }
                    Button("추가") {
                        let newPlaylist = Playlist(
                            id: UUID().uuidString, // ✅ UUID → String 변환
                            name: newPlaylistName,
                            description: "설명을 입력하세요",
                            createdDate: Date(), // ✅ 현재 날짜로 설정
                            videoIds: [],
                            thumbnailURL: nil,
                            defaultThumbnailName: "default_playlist_image1", // ✅ 기본 이미지 이름 설정
                            ownerId: "default_owner" // ✅ 소유자 ID (필요에 따라 변경)
                        )

                        PlaylistService.shared.addPlaylist(newPlaylist)
                        showAddPlaylistAlert = false
                        sheetManager.presentPlaylistDetail(for: newPlaylist)
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
