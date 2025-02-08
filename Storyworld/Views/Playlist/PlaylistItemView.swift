import SwiftUI

struct PlaylistItemView: View {
    let playlist: Playlist
    @State private var localPlaylistImage: UIImage? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                // ✅ 1. 로컬 캐시된 이미지 먼저 표시
                if let localImage = localPlaylistImage {
                    Image(uiImage: localImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                // ✅ 2. Firebase에서 썸네일 다운로드
                else if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
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
                }
                // ✅ 3. 썸네일 없을 경우 기본 이미지
                else {
                    Image(playlist.defaultThumbnailName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(playlist.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(UIColor(hex:"#ffffff")))
                    .padding(.bottom, 4)
                
                Text("\(playlist.videoIds.count)개의 영상")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(UIColor(hex:"#CECECE")))
            }
            
            Spacer()
        }
        .onAppear {
            if let localImage = PlaylistService.shared.loadPlaylistImageLocally(playlist.id) {
                self.localPlaylistImage = localImage
            } else if let urlString = playlist.thumbnailURL, let url = URL(string: urlString) {
                PlaylistService.shared.downloadImage(from: url, for: playlist.id) { image in
                    if let downloadedImage = image {
                        self.localPlaylistImage = downloadedImage
                        PlaylistService.shared.savePlaylistImageLocally(playlist.id, image: downloadedImage)
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .playlistUpdated)) { notification in
            if let userInfo = notification.userInfo,
               let updatedPlaylistID = userInfo["playlistID"] as? String,
               updatedPlaylistID == playlist.id,
               let updatedImage = userInfo["image"] as? UIImage {
                print("✅ PlaylistItemView에서 썸네일 업데이트 감지: \(updatedPlaylistID)")
                self.localPlaylistImage = updatedImage
            }
        }
    }
}
