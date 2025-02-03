//
//  PlaylistService.swift
//  Storyworld
//
//  Created by peter on 1/23/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import FirebaseFunctions

class PlaylistService {
    static let shared = PlaylistService()
    private let userService = UserService.shared
    
    private let functions = Functions.functions()
    
    // MARK: - 플레이리스트 생성
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
        
        // 1) UserDefaults에 즉시 저장
        var localPlaylists = loadPlaylists()
        localPlaylists.append(newPlaylist)
        UserDefaults.standard.savePlaylists(localPlaylists)
        
        // 2) Cloud Function 호출: createPlaylist
        let requestData: [String: Any] = [
            "playlistId": newPlaylist.id,
            "name": newPlaylist.name,
            "description": newPlaylist.description ?? "",
            "createdDate": isoString(newPlaylist.createdDate),
            "thumbnailURL": newPlaylist.thumbnailURL as Any,
            "defaultThumbnailName": newPlaylist.defaultThumbnailName
        ]
        
        do {
            let _ = try await functions.httpsCallable("createPlaylist").call(requestData)
            print("🔥 [CF] 플레이리스트 생성 완료: \(newPlaylist.id)")
        } catch {
            print("❌ [CF] 플레이리스트 생성 실패: \(error.localizedDescription)")
        }
        
        return newPlaylist
    }
    
    // MARK: - 플레이리스트 저장 (UserDefaults + CF)
    private func savePlaylists(_ playlists: [Playlist]) async {
        UserDefaults.standard.savePlaylists(playlists) // 로컬 저장
        // 이전엔 Firestore에 직접 setData했지만, 이제 CF로 대체 가능
        // 다만, 생성/삭제/수정별로 개별 함수 호출이 편하므로, 여기선 별도 CF는 호출하지 않음
        // (createNewPlaylist, removePlaylist, updatePlaylistDetails 등 각 케이스별 함수를 사용)
    }
    
    func loadPlaylists() -> [Playlist] {
        return UserDefaults.standard.loadPlaylists()
    }
    
    // MARK: - 플레이리스트 삭제
    func removePlaylist(_ id: String) async {
        var playlists = loadPlaylists()
        playlists.removeAll { $0.id == id }
        await savePlaylists(playlists)
        
        // Cloud Function 호출: removePlaylist
        let requestData: [String: Any] = [
            "playlistId": id
        ]
        
        do {
            let _ = try await functions.httpsCallable("removePlaylist").call(requestData)
            print("✅ [CF] Firestore에서 플레이리스트 삭제 완료! ID: \(id)")
        } catch {
            print("❌ [CF] 플레이리스트 삭제 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 플레이리스트에서 영상 제거
    func removeVideoFromPlaylist(_ video: CollectedVideo, playlist: Playlist) async {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // 1) 로컬 업데이트
            playlists[index].videoIds.removeAll { $0 == video.id }
            await savePlaylists(playlists)
            
            // 2) CF 호출: removeVideoFromPlaylist
            let requestData: [String: Any] = [
                "playlistId": playlist.id,
                "videoId": video.id
            ]
            do {
                let _ = try await functions.httpsCallable("removeVideoFromPlaylist").call(requestData)
                print("✅ [CF] Firestore & UserDefaults에서 플레이리스트 업데이트 완료!")
            } catch {
                print("❌ [CF] 플레이리스트 업데이트 실패: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    // MARK: - 플레이리스트에 영상 추가
    func addVideoToPlaylist(_ video: CollectedVideo, to playlist: Playlist) async {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == playlist.id }) {
            // 1) 로컬 업데이트
            playlists[index].videoIds.append(video.video.videoId)
            await savePlaylists(playlists)
            
            // 2) CF 호출: addVideoToPlaylist
            let requestData: [String: Any] = [
                "playlistId": playlist.id,
                "videoId": video.id
            ]
            do {
                let _ = try await functions.httpsCallable("addVideoToPlaylist").call(requestData)
                print("✅ [CF] Firestore & UserDefaults 플레이리스트 업데이트 완료!")
            } catch {
                print("❌ [CF] 플레이리스트 업데이트 실패: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    
    // MARK: - 플레이리스트 이름/설명 수정
    func updatePlaylistDetails(id: String, newName: String?, newDescription: String?) async {
        var playlists = loadPlaylists()
        if let index = playlists.firstIndex(where: { $0.id == id }) {
            if let newName = newName {
                playlists[index].name = newName
            }
            if let newDescription = newDescription {
                playlists[index].description = newDescription
            }
            
            await savePlaylists(playlists)
            
            // Cloud Function: updatePlaylistDetails
            let requestData: [String: Any] = [
                "playlistId": id,
                "newName": newName ?? "",
                "newDescription": newDescription ?? ""
            ]
            
            do {
                let _ = try await functions.httpsCallable("updatePlaylistDetails").call(requestData)
                print("✅ [CF] 플레이리스트 업데이트 완료! \(playlists[index].name)")
            } catch {
                print("❌ [CF] 업데이트 실패: \(error.localizedDescription)")
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .playlistUpdated, object: nil)
            }
        }
    }
    // MARK: - Firestore → UserDefaults 동기화
    func syncPlaylistsWithFirestore() async {
        guard let currentUser = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 사용자가 없습니다.")
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(currentUser.uid)
        
        do {
            let snapshot = try await userRef.collection("playlists")
                .order(by: "createdDate", descending: false)
                .getDocuments()
            
            let playlists = snapshot.documents.compactMap { try? $0.data(as: Playlist.self) }
            UserDefaults.standard.savePlaylists(playlists)
            print("✅ Firestore -> UserDefaults playlists 동기화 완료! (총 \(playlists.count)개)")
        } catch {
            print("❌ 플레이리스트 동기화 실패: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 유틸: Date → String
    private func isoString(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }
    
}

extension Notification.Name {
    static let playlistUpdated = Notification.Name("playlistUpdated")
}
