//
//  PlaylistService.swift
//  Storyworld
//
//  Created by peter on 1/23/25.
//

import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import FirebaseStorage

class PlaylistService {
    static let shared = PlaylistService()
    private let userService = UserService.shared
    
    func createNewPlaylist(name: String) async -> Playlist? {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 로그인된 사용자 없음")
            return nil
        }
        
        let newPlaylist = Playlist(
            id: UUID().uuidString,
            name: name,
            description: "설명을 입력하세요",
            createdDate: Date(),
            videoIds: [],
            thumbnailURL: nil,
            defaultThumbnailName: "default_playlist_image1",
            ownerId: currentUser.uid
        )
        
        await addPlaylist(newPlaylist) // ✅ Firestore & UserDefaults에 저장
        return newPlaylist // ✅ 생성한 플레이리스트 반환
    }
    
    private func savePlaylists(_ playlists: [Playlist]) async {
        UserDefaults.standard.savePlaylists(playlists) // ✅ UserDefaults 저장
        
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        do {
            for playlist in playlists {
                try userRef.collection("playlists").document(playlist.id).setData(from: playlist)
            }
            print("🔥 Firestore에 플레이리스트 저장 완료!")
        } catch {
            print("❌ Firestore에 플레이리스트 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func loadPlaylists() -> [Playlist] {
        var playlists = UserDefaults.standard.loadPlaylists()
        
        // ✅ 플레이리스트별로 이미지 로드
        for index in playlists.indices {
            let playlistID = playlists[index].id
            
            // ✅ 1. 로컬에 저장된 이미지 불러오기
            if let localImage = PlaylistService.shared.loadPlaylistImageLocally(playlistID) {
                playlists[index].thumbnailURL = nil // 로컬 이미지 사용
                print("✅ 로컬에서 플레이리스트 이미지 로드 완료")
                
                // ✅ 2. 로컬에 없으면 Firebase에서 다운로드
            } else if let urlString = playlists[index].thumbnailURL, let url = URL(string: urlString) {
                PlaylistService.shared.downloadImage(from: url, for: playlistID) { image in
                    if let downloadedImage = image {
                        // ✅ 다운로드된 이미지를 로컬에 저장
                        PlaylistService.shared.savePlaylistImageLocally(playlistID, image: downloadedImage)
                        print("✅ Firebase에서 다운로드 후 로컬 저장 완료")
                    }
                }
            }
        }
        
        return playlists
    }
    
    func addPlaylist(_ playlist: Playlist) async {
        var playlists = loadPlaylists()
        playlists.append(playlist)
        await savePlaylists(playlists)
    }
    
    // ✅ 플레이리스트 삭제
    func removePlaylist(_ id: String) async {
        var playlists = loadPlaylists()
        playlists.removeAll { $0.id == id }
        await savePlaylists(playlists)
        
        // ✅ Firestore에서도 삭제
        guard let currentUser = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        try? await db.collection("users").document(currentUser.uid)
            .collection("playlists").document(id).delete()
        print("✅ Firestore에서 플레이리스트 삭제 완료!")
    }
    
    func removeVideoFromPlaylist(_ video: CollectedVideo, playlist: Playlist) async {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // ✅ 로컬 UserDefaults 업데이트
            playlists[index].videoIds.removeAll { $0 == video.id }
            await savePlaylists(playlists)
            
            // ✅ Firestore 업데이트
            await updatePlaylistInFirestore(playlists[index])
            
            print("✅ Firestore & UserDefaults에서 플레이리스트 업데이트 완료! \(playlists[index].videoIds)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    func addVideoToPlaylist(_ video: CollectedVideo, to playlist: Playlist) async {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // ✅ 로컬 UserDefaults 업데이트
            playlists[index].videoIds.append(video.video.videoId)
            await savePlaylists(playlists)
            
            // ✅ Firestore 업데이트
            await updatePlaylistInFirestore(playlists[index])
            
            print("✅ Firestore & UserDefaults에서 플레이리스트 업데이트 완료! \(playlists[index].videoIds)")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    func updatePlaylistDetails(id: String, newName: String?, newDescription: String?) async {
        var playlists = loadPlaylists()
        
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            if let newName = newName {
                playlists[index].name = newName
            }
            if let newDescription = newDescription {
                playlists[index].description = newDescription
            }
            
            await savePlaylists(playlists) // ✅ UserDefaults에 저장
            
            // ✅ Firestore 업데이트
            await updatePlaylistInFirestore(playlists[index])
            
            print("✅ Firestore & UserDefaults에서 플레이리스트 업데이트 완료! \(playlists[index].name), \(playlists[index].description ?? "설명 없음")")
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    
    func updatePlaylistInFirestore(_ playlist: Playlist) async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        let playlistRef = userRef.collection("playlists").document(playlist.id)
        
        do {
            try playlistRef.setData(from: playlist)
            print("🔥 Firestore에서 플레이리스트 업데이트 완료! ID: \(playlist.id)")
        } catch {
            print("❌ Firestore에서 플레이리스트 업데이트 실패: \(error.localizedDescription)")
        }
    }
    
    /// ✅ Firestore → UserDefaults로 `playlists` 동기화 (생성 순서 유지)
    func syncPlaylistsWithFirestore() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        do {
            let snapshot = try await userRef.collection("playlists")
                .order(by: "createdDate", descending: false) // ✅ 생성 순서대로 가져오기
                .getDocuments()
            
            let playlists = snapshot.documents.compactMap { try? $0.data(as: Playlist.self) }
            
            // ✅ UserDefaults에 저장 (순서 유지)
            UserDefaults.standard.savePlaylists(playlists)
            print("✅ Firestore에서 playlists 불러와서 UserDefaults에 저장 완료! (총 \(playlists.count)개)")
        } catch {
            print("❌ Firestore에서 playlists 불러오기 실패: \(error.localizedDescription)")
        }
    }
    @Published var isUploading = false // ✅ 업로드 상태 추적

    func uploadPlaylistThumbnail(playlist: Playlist, image: UIImage) async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 로그인된 유저가 없습니다.")
            return
        }

        // ✅ 1) 로컬 저장 (즉시 반영)
        self.savePlaylistImageLocally(playlist.id, image: image)

        // ✅ 2) Firebase Storage에 업로드
        let resizedImage = image.resized(toWidth: 200)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            print("❌ 이미지 JPEG 변환 실패")
            return
        }

        let storageRef = Storage.storage().reference()
        let playlistImageRef = storageRef.child("playlist_images/\(currentUser.uid)_\(playlist.id).jpg")

        do {
            let _ = try await playlistImageRef.putDataAsync(imageData) // ✅ async 업로드
            let downloadURL = try await playlistImageRef.downloadURL() // ✅ 업로드 후 URL 가져오기

            // ✅ Firestore 업데이트
            await updatePlaylistThumbnailURL(playlist: playlist, url: downloadURL)

            print("✅ 썸네일 업로드 완료: \(downloadURL)")

            // ✅ 변경 사항을 NotificationCenter로 알림
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil, userInfo: ["playlistID": playlist.id, "image": image])
            }
        } catch {
            print("❌ 썸네일 업로드 실패: \(error.localizedDescription)")
        }
    }
    
    /// ✅ Firestore의 playlist.thumbnailURL 업데이트
    func updatePlaylistThumbnailURL(playlist: Playlist, url: URL) async {
        var updatedPlaylist = playlist
        updatedPlaylist.thumbnailURL = url.absoluteString

        // ✅ 1. UserDefaults에서 개별 업데이트
        var playlists = UserDefaults.standard.loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            playlists[index].thumbnailURL = url.absoluteString
            UserDefaults.standard.savePlaylists(playlists) // 🔥 특정 플레이리스트만 저장
        }

        // ✅ 2. Firestore 업데이트
        await updatePlaylistInFirestore(updatedPlaylist)

        print("✅ 특정 플레이리스트의 썸네일 URL 업데이트 완료: \(url.absoluteString)")

        // ✅ 3. 변경 사항을 Notification으로 전달 (뷰 업데이트 트리거)
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .playlistUpdated, object: nil)
        }
    }
    
    // ✅ Documents 디렉토리 경로
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    /// ✅ 로컬에 플레이리스트 이미지를 저장
    func savePlaylistImageLocally(_ playlistID: String, image: UIImage) {
        let fileURL = getDocumentsDirectory().appendingPathComponent("playlist_\(playlistID).jpg")
        
        // 압축하여 저장
        if let data = image.jpegData(compressionQuality: 0.8) {
            do {
                try data.write(to: fileURL)
                print("✅ 플레이리스트 이미지 로컬 저장 완료: \(fileURL.path)")
            } catch {
                print("❌ 플레이리스트 이미지 로컬 저장 실패: \(error.localizedDescription)")
            }
        }
    }
    
    /// ✅ 로컬에서 플레이리스트 이미지 불러오기
    func loadPlaylistImageLocally(_ playlistID: String) -> UIImage? {
        let fileURL = getDocumentsDirectory().appendingPathComponent("playlist_\(playlistID).jpg")
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            return UIImage(data: data)
        } catch {
            print("❌ 로컬 플레이리스트 이미지 로드 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    func downloadImage(from url: URL, for playlistID: String, completion: @escaping (UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    // ✅ 이미지 다운로드 성공 후, 즉시 로컬에 저장
                    self.savePlaylistImageLocally(playlistID, image: image)
                    completion(image)
                }
            } else {
                print("❌ 이미지 다운로드 실패: \(error?.localizedDescription ?? "알 수 없는 오류")")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }.resume()
    }
    
    func loadPlaylistImage(_ playlistID: String) {
        // ✅ 1) 로컬 캐시된 이미지 먼저 적용
        if let localImage = loadPlaylistImageLocally(playlistID) {
            print("✅ 로컬에서 플레이리스트 이미지 로드 완료: \(playlistID)")
            
            // ✅ 2) 로컬에 없으면 Firebase에서 다운로드
        } else if let playlist = UserDefaults.standard.loadPlaylists().first(where: { $0.id == playlistID }),
                  let urlString = playlist.thumbnailURL,
                  let url = URL(string: urlString) {
            
            downloadImage(from: url, for: playlistID) { image in
                if let downloadedImage = image {
                    self.savePlaylistImageLocally(playlistID, image: downloadedImage)
                    print("✅ Firebase에서 다운로드 후 로컬 저장 완료: \(playlistID)")
                }
            }
        }
    }
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
