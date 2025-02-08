import SwiftUI
import PhotosUI

struct PlaylistDetailedView: View {
    var playlist: Playlist
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @ObservedObject var sheetManager: SheetManager
    @StateObject private var viewModel = PlaylistDetailedViewModel()
    @State private var currentPlaylist: Playlist
    @State private var localPlaylistImage: UIImage? = nil
    
    // 기존 State
    @State private var showTitleAlert = false
    @State private var showDescriptionAlert = false
    @State private var updatedTitle: String = ""
    @State private var updatedDescription: String = ""
    @State private var showActionSheet = false
    @State private var showDeleteConfirmationAlert = false
    
    // ✅ 플레이리스트 이미지 변경 관련 State
    @State private var isShowingPlaylistImagePicker = false
    @State private var selectedPlaylistImage: UIImage? = nil
    
    // ✅ 썸네일 업로드 로딩 표시
    @State private var isUploadingThumbnail = false

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
                    ZStack {
                        Button(action: {
                            checkPermission(for: .photoLibrary) { granted in
                                if granted {
                                    isShowingPlaylistImagePicker = true
                                } else {
                                    print("❌ 사진 권한 거부됨")
                                }
                            }
                        }) {
                            if let localImage = localPlaylistImage {
                                // ✅ 로컬 이미지 먼저 표시
                                Image(uiImage: localImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle()) // 동그랗게 표시
                                    .shadow(radius: 5)
                            } else if let urlString = currentPlaylist.thumbnailURL, let url = URL(string: urlString) {
                                // ✅ Firebase Storage URL로부터 다운로드
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 80, height: 80)
                                        .clipShape(Circle())
                                        .shadow(radius: 5)
                                } placeholder: {
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                }
                            } else {
                                // 기본 썸네일 표시
                                Image(currentPlaylist.defaultThumbnailName)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .shadow(radius: 5)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        // 타이틀 수정 버튼
                        Button(action: {
                            UIImpactFeedbackGenerator.trigger(.light)
                            updatedTitle = currentPlaylist.name
                            showTitleAlert = true
                        }) {
                            Text(currentPlaylist.name)
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
                
                // 기존 비디오 목록 로직
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
                                        Task {
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
            // 플레이리스트 삭제 버튼 등 기존 로직 유지
            .overlay(
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
                    .padding(.bottom, 20)
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
                            showDeleteConfirmationAlert = true
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
                                await PlaylistService.shared.removePlaylist(currentPlaylist.id)
                            }
                            sheetManager.dismissPlaylistDetail()
                        }
                    }
                }
            }
            .onAppear {
                viewModel.loadVideosInPlaylist(for: currentPlaylist)
            }
            .onAppear {
                loadPlaylistImage()
            }
            .onChange(of: playlist.id) { _ in
                loadPlaylistImage()
            }
            .alert("플레이리스트 이름 변경", isPresented: $showTitleAlert) {
                TextField("새 이름", text: $updatedTitle)
                Button("저장") {
                    Task {
                        await PlaylistService.shared.updatePlaylistDetails(
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
                    Task {
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
            
            // ✅ 사진 라이브러리 피커 Sheet
            .sheet(isPresented: $isShowingPlaylistImagePicker, onDismiss: handlePlaylistImageSelection) {
                ImagePickerManager(image: $selectedPlaylistImage, sourceType: .photoLibrary)
            }
        }
    }
    
    // ✅ 새로운 함수 추가
    private func loadPlaylistImage() {
        // ✅ 1) 로컬에 저장된 이미지 먼저 적용
        if let localImage = PlaylistService.shared.loadPlaylistImageLocally(playlist.id) {
            self.localPlaylistImage = localImage
            print("✅ 로컬에서 플레이리스트 이미지 로드 완료")
        } else if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
            // ✅ 2) 로컬에 없으면 Firebase에서 다운로드
            PlaylistService.shared.downloadImage(from: url, for: playlist.id) { image in
                if let downloadedImage = image {
                    self.localPlaylistImage = downloadedImage
                    print("✅ Firebase에서 이미지 다운로드 후 로컬 저장 완료")
                }
            }
        }
    }
    
    // MARK: - 이미지를 고른 뒤 업로드 처리
    private func handlePlaylistImageSelection() {
        guard let selectedImage = selectedPlaylistImage else { return }

        // ✅ 1) UI에 즉시 반영
        self.localPlaylistImage = selectedImage

        // ✅ 2) 로컬 파일에도 즉시 저장
        PlaylistService.shared.savePlaylistImageLocally(currentPlaylist.id, image: selectedImage)

        // ✅ 3) Firebase Storage에 업로드 (비동기 처리)
        isUploadingThumbnail = true
        PlaylistService.shared.uploadPlaylistThumbnail(playlist: currentPlaylist, image: selectedImage) { url in
            DispatchQueue.main.async {
                self.isUploadingThumbnail = false
            }
            guard let url = url else { return }

            // ✅ Firestore 업데이트 (thumbnailURL 동기화)
            DispatchQueue.main.async {
                self.currentPlaylist.thumbnailURL = url.absoluteString
            }
        }
    }
}
