import SwiftUI

struct PlaylistDetailedView: View {
    var playlist: Playlist
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @ObservedObject var sheetManager: SheetManager
    @StateObject private var viewModel = PlaylistDetailedViewModel()
    @State private var currentPlaylist: Playlist
    @State private var showTitleAlert = false
    @State private var showDescriptionAlert = false
    @State private var updatedTitle: String = ""
    @State private var updatedDescription: String = ""
    @State private var showActionSheet = false
    @State private var showDeleteConfirmationAlert = false
    
    init(playlist: Playlist, playlistViewModel: PlaylistViewModel, sheetManager: SheetManager) {
        self.playlist = playlist
        self._currentPlaylist = State(initialValue: playlist)
        self.playlistViewModel = playlistViewModel
        self.sheetManager = sheetManager
    }
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    // 썸네일 이미지 표시
                    if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .cornerRadius(12)
                        } placeholder: {
                            Image(playlist.defaultThumbnailName)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 80)
                                .cornerRadius(12)
                        }
                    } else {
                        Image(playlist.defaultThumbnailName)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 80)
                            .cornerRadius(12)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // 타이틀 수정 버튼
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            updatedTitle = currentPlaylist.name  // playlist → currentPlaylist로 변경
                            showTitleAlert = true
                        }) {
                            Text(currentPlaylist.name)  // playlist → currentPlaylist로 변경
                                .font(.title2)
                                .foregroundColor(Color(UIColor(hex:"#ffffff")))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.vertical, 4)
                        
                        // 설명 수정 버튼
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            updatedDescription = currentPlaylist.description ?? "설명을 입력하세요"
                            showDescriptionAlert = true
                        }) {
                            Text(currentPlaylist.description ?? "설명을 입력하세요")
                                .font(.body)
                                .foregroundColor(Color(UIColor(hex:"#CECECE")))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
                .padding()
                
                if viewModel.videosInPlaylist.isEmpty {
                    Text("No Video")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundColor(Color(UIColor(hex:"#CECECE")))
                        .multilineTextAlignment(.center)
                        .padding()
                        .padding(.top, 48)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(viewModel.videosInPlaylist, id: \.video.videoId) { video in
                                PlaylistVideoItemView(
                                    collectedVideo: video,
                                    isInPlaylist: true,
                                    onAdd: {},
                                    onRemove: {
                                        Task{
                                         await PlaylistService.shared.removeVideoFromPlaylist(video, playlist: currentPlaylist)
                                        }
                                        DispatchQueue.main.async {
                                            currentPlaylist.videoIds.removeAll { $0 == video.video.videoId }
                                            viewModel.loadVideosInPlaylist(for: currentPlaylist)
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 80)
                    }
                }
                Spacer()
            }
            .background(Color(UIColor(hex:"#1D1D1D")))
            .overlay(
                VStack {
                    Spacer() // 상단 공간 확보
                    HStack {
                        Spacer() // 좌측 공간 확보
                        Button(action: {
                            sheetManager.presentAddVideoSheet()
                        }) {
                            Text("영상 추가")
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showActionSheet = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .actionSheet(isPresented: $showActionSheet) {
                ActionSheet(
                    title: Text("Playlist Setting"),
                    buttons: [
                        .destructive(Text("플레이리스트 삭제")) {
                            showDeleteConfirmationAlert = true  // 삭제 확인 Alert 표시
                        },
                        .cancel()
                    ]
                )
            }
            .alert("정말 삭제하시겠습니까?", isPresented: $showDeleteConfirmationAlert) {
                VStack {
                    HStack {
                        Button("취소", role: .cancel) {}
                        Button("삭제", role: .destructive) {
                            Task {
                             await   PlaylistService.shared.removePlaylist(currentPlaylist.id)
                            }
                            sheetManager.dismissPlaylistDetail()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadVideosInPlaylist(for: currentPlaylist)
            }
        }
        .alert("플레이리스트 이름 변경", isPresented: $showTitleAlert) {
            TextField("새 이름", text: $updatedTitle)
            Button("저장") {
                Task {
                 await   PlaylistService.shared.updatePlaylistDetails(
                        id: currentPlaylist.id,
                        newName: updatedTitle,
                        newDescription: nil
                    )
                }
                currentPlaylist.name = updatedTitle
            }
            Button("취소", role: .cancel) {}
        }
        .alert("플레이리스트 설명 변경", isPresented: $showDescriptionAlert) {
            TextField("새 설명", text: $updatedDescription)
            Button("저장") {
                Task{
                    await PlaylistService.shared.updatePlaylistDetails(
                        id: currentPlaylist.id,
                        newName: nil,
                        newDescription: updatedDescription
                    )
                }
                currentPlaylist.description = updatedDescription
            }
            Button("취소", role: .cancel) {}
        }
        .sheet(isPresented: $sheetManager.showAddVideoSheet, onDismiss: {
            viewModel.loadVideosInPlaylist(for: currentPlaylist)
        }) {
            PlaylistAddVideoView(
                playlist: $currentPlaylist,
                playlistViewModel: playlistViewModel
            )
        }
    }
}
