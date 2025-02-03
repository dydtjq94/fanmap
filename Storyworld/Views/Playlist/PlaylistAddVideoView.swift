//
//  PlaylistAddVideoView.swift
//  Storyworld
//
//  Created by peter on 1/22/25.
//

import SwiftUI

struct PlaylistAddVideoView: View {
    @Binding var playlist: Playlist
    @ObservedObject var playlistViewModel: PlaylistViewModel
    @StateObject private var viewModel = PlaylistDetailedViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.videosNotInPlaylist.isEmpty {
                    Text("추가할 영상이 없습니다.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(viewModel.videosNotInPlaylist, id: \.video.videoId) { video in
                                PlaylistVideoItemView(
                                    collectedVideo: video,
                                    isInPlaylist: false,
                                    onAdd: {
                                        Task{
                                            await PlaylistService.shared.addVideoToPlaylist(video, to: playlist)
                                        }
                                        DispatchQueue.main.async {
                                            playlist.videoIds.append(video.video.videoId)
                                            viewModel.videosNotInPlaylist.removeAll { $0.video.videoId == video.video.videoId }
                                            NotificationCenter.default.post(name: .playlistUpdated, object: nil)
                                        }
                                    },
                                    onRemove: {}
                                )
                                .padding(.horizontal)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("영상 추가")
            .onAppear {
                viewModel.loadVideosNotInPlaylist(for: playlist)
            }
        }
    }
}
