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
                try await userRef.collection("playlists").document(playlist.id).setData(from: playlist)
            }
            print("🔥 Firestore에 플레이리스트 저장 완료!")
        } catch {
            print("❌ Firestore에 플레이리스트 저장 실패: \(error.localizedDescription)")
        }
    }
    
    func loadPlaylists() -> [Playlist] {
        return UserDefaults.standard.loadPlaylists()
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
            try await playlistRef.setData(from: playlist)
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

}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
