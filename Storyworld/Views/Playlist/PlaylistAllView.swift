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
                // ✅ 플레이리스트가 없을 때 표시되는 메시지
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
