////
////  dummy.swift
////  Storyworld
////
////  Created by peter on 1/23/25.
////
//
//
//
//
////
////  PlaylistDetailedView.swift
////  Storyworld
////
////  Created by peter on 1/22/25.
////
//
//import SwiftUI
//
//struct PlaylistDetailedView: View {
//    @Binding var playlist: Playlist
//    var onSave: (Playlist) -> Void
//    var onDelete: () -> Void
//    @Environment(\.presentationMode) var presentationMode
//
//    @State private var showTitleAlert = false
//    @State private var showDescriptionAlert = false
//    @State private var showActionSheet = false
//    @State private var showAddVideoSheet = false
//    @State private var updatedTitle = ""
//    @State private var updatedDescription = ""
//
//    var body: some View {
//        NavigationView {
//            VStack(spacing: 16) {
//                HStack {
//                    // 썸네일 이미지 표시
//                    if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
//                        AsyncImage(url: url) { image in
//                            image
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 80)
//                                .cornerRadius(12)
//                        } placeholder: {
//                            Image(playlist.defaultThumbnailName) // 기본 이미지 적용
//                                .resizable()
//                                .scaledToFit()
//                                .frame(height: 80)
//                                .cornerRadius(12)
//                        }
//                    } else {
//                        Image(playlist.defaultThumbnailName) // 기본 이미지 적용
//                            .resizable()
//                            .scaledToFit()
//                            .frame(height: 80)
//                            .cornerRadius(12)
//                    }
//
//                    VStack(alignment: .leading, spacing: 8) {
//                        // 타이틀 수정 버튼
//                        Button(action: {
//                            updatedTitle = playlist.name
//                            showTitleAlert = true
//                        }) {
//                            Text(playlist.name)
//                                .font(.title2)
//                                .foregroundColor(.primary)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                        .padding(.vertical, 4)
//
//                        // 설명 수정 버튼
//                        Button(action: {
//                            updatedDescription = playlist.description ?? ""
//                            showDescriptionAlert = true
//                        }) {
//                            Text(playlist.description ?? "설명을 입력하세요")
//                                .font(.body)
//                                .foregroundColor(.secondary)
//                                .frame(maxWidth: .infinity, alignment: .leading)
//                        }
//                        .padding(.vertical, 4)
//                    }
//                }
//
//                Spacer()
//                
//                ScrollView {
//                    VStack(spacing: 8) {
//                        ForEach(filteredVideos(), id: \.video.videoId) { video in
//                            PlaylistVideoItemView(
//                                collectedVideo: video,
//                                isInPlaylist: true,
//                                onAdd: {},
//                                onRemove: {
//                                    removeVideoFromPlaylist(video)
//                                }
//                            )
//                            .padding(.horizontal)
//                            .background(Color.gray.opacity(0.1))  // 회색 네모 스타일 적용
//                            .cornerRadius(10)
//                        }
//                    }
//                    .padding(.top, 8)
//                }
//
//                // 영상 추가 버튼
//                Button(action: {
//                    showAddVideoSheet = true
//                }) {
//                    Text("영상 추가")
//                        .font(.headline)
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(10)
//                        .shadow(radius: 5)
//                }
//                .padding(.horizontal)
//                .padding(.bottom, 16)
//            }
//            .padding()
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        showActionSheet = true
//                    }) {
//                        Image(systemName: "gearshape.fill")
//                            .foregroundColor(.gray)
//                    }
//                }
//            }
//            .actionSheet(isPresented: $showActionSheet) {
//                ActionSheet(
//                    title: Text("설정"),
//                    message: Text("원하는 작업을 선택하세요."),
//                    buttons: [
//                        .destructive(Text("삭제")) {
//                            deletePlaylist()
//                        },
//                        .cancel()
//                    ]
//                )
//            }
//            .alert("제목 수정", isPresented: $showTitleAlert) {
//                TextField("새 제목 입력", text: $updatedTitle)
//                Button("확인") {
//                    playlist.name = updatedTitle
//                    onSave(playlist)
//                }
//                Button("취소", role: .cancel) {}
//            }
//            .alert("설명 수정", isPresented: $showDescriptionAlert) {
//                TextField("새 설명 입력", text: $updatedDescription)
//                Button("확인") {
//                    playlist.description = updatedDescription.isEmpty ? nil : updatedDescription
//                    onSave(playlist)
//                }
//                Button("취소", role: .cancel) {}
//            }
//        }
//        .sheet(isPresented: $showAddVideoSheet) {
//            PlaylistAddVideoView()
//            
//        }
//    }
//
//    private func savePlaylist() {
//        onSave(playlist)
//    }
//
//    private func deletePlaylist() {
//        onDelete()
//        presentationMode.wrappedValue.dismiss()
//    }
//}
//
//
//import SwiftUI
//
//struct PlaylistVideoItemView: View {
//    let collectedVideo: CollectedVideo
//    let isInPlaylist: Bool
//    var onAdd: () -> Void
//    var onRemove: () -> Void
//
//    var body: some View {
//        HStack(alignment: .top, spacing: 12) {
//            AsyncImage(url: URL(string: collectedVideo.video.thumbnailURL)) { image in
//                image
//                    .resizable()
//                    .scaledToFit()
//                    .frame(width: 72)
//                    .cornerRadius(8)
//            } placeholder: {
//                Color.gray
//                    .frame(width: 72, height: 48)
//                    .cornerRadius(8)
//            }
//            
//            VStack(alignment: .leading, spacing: 6) {
//                Text(collectedVideo.video.title)
//                    .font(.system(size: 14, weight: .bold))
//                    .lineLimit(2)
//                    .foregroundColor(.white)
//
//                Text(Channel.getChannelName(by: collectedVideo.video.channelId))
//                    .font(.system(size: 12, weight: .regular))
//                    .foregroundColor(.gray)
//                    .lineLimit(1)
//            }
//            .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Spacer()
//
//            // + 버튼 (추가) 또는 - 버튼 (제거) 조건에 따라 표시
//            Button(action: {
//                isInPlaylist ? onRemove() : onAdd()
//            }) {
//                Image(systemName: isInPlaylist ? "minus.circle.fill" : "plus.circle.fill")
//                    .foregroundColor(isInPlaylist ? .red : .blue)
//                    .font(.title2)
//            }
//        }
//    }
//}
