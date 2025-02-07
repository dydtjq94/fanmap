//
//  LoginService.swift
//  Storyworld
//
//  Created by peter on 2/3/25.
//

import SwiftUI
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import CryptoKit

@MainActor
class LoginService: ObservableObject {
    static let shared = LoginService()
    
    @AppStorage("isUserInitialized") private var isUserInitialized: Bool = false
    private var currentNonce: String?
    private let userService = UserService.shared
    
    // ✅ Apple 로그인 버튼 요청 처리 (Nonce 생성)
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email] // ✅ 이메일 요청 추가
        request.nonce = sha256(nonce)
    }
    
    // ✅ Apple 로그인 완료 후 Firebase 인증 진행
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authResults):
            if let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential {
                Task {
                    await signInWithApple(credential: appleIDCredential)
                }
            }
        case .failure(let error):
            print("❌ Apple Sign In failed: \(error.localizedDescription)")
        }
    }
    
    // ✅ Apple 로그인 후 Firebase Auth 연동 (async 적용)
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce, let appleIDToken = credential.identityToken else {
            print("❌ Invalid login request.")
            return
        }
        
        let idTokenString = String(data: appleIDToken, encoding: .utf8)
        let firebaseCredential = OAuthProvider.credential(
            providerID: AuthProviderID.apple, // 🔥 문자열 대신 AuthProviderID 사용
            idToken: idTokenString ?? "",
            rawNonce: nonce,
            accessToken: nil
        )
        
        do {
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            let user = authResult.user
            let uid = user.uid
            let email = user.email ?? "unknown@apple.com" // ✅ Apple 로그인 시 이메일이 없을 수도 있음
            let nickname = credential.fullName?.givenName ?? "개청자 \(Int.random(in: 1000...9999))"
            
            await handleLoginSuccess(uid: uid, email: email, nickname: nickname)
        } catch {
            print("❌ Firebase Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
    
    // ✅ 로그인 성공 후 Firestore → UserDefaults 저장 (async 적용)
    private func handleLoginSuccess(uid: String, email: String, nickname: String) async {
        if let existingUser = await fetchUserData(uid: uid) {
            // ✅ 기존 유저: UserDefaults 업데이트
            print("✅ 기존 유저 Firestore에서 불러옴: \(existingUser.nickname)")
            userService.saveUser(existingUser)
        } else {
            // ✅ 신규 유저 생성 후 저장
            print("🆕 신규 유저 생성 및 저장")
            let newUser = User(
                id: uid,
                email: email,
                nickname: nickname,
                profileImageURL: nil,
                bio: "소개글을 작성하세요",
                experience: 0,
                balance: 1000,
                gems: 0
            )
            await saveUserToFirestore(uid: uid, userData: newUser)
            userService.saveUser(newUser)
        }
        
        // ✅ Firestore → UserDefaults로 collectedVideos 동기화
        await CollectionService.shared.syncCollectedVideosWithFirestore()
        
        // ✅ Firestore → UserDefaults로 `playlists` 동기화 (새로 추가)
        await PlaylistService.shared.syncPlaylistsWithFirestore()
        
        DispatchQueue.main.async { [weak self] in
            self?.isUserInitialized = true
        }
    }
    
    // ✅ Firestore에서 유저 정보 가져오기 (async 적용)
    func fetchUserData(uid: String) async -> User? {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        do {
            let userSnapshot = try await userRef.getDocument()
            guard let userData = userSnapshot.data() else { return nil }
            
            let user = User(
                id: uid,
                email: userData["email"] as? String ?? "",
                nickname: userData["nickname"] as? String ?? "",
                profileImageURL: userData["profileImageURL"] as? String,
                bio: userData["bio"] as? String ?? "",
                experience: userData["experience"] as? Int ?? 0,
                balance: userData["balance"] as? Int ?? 0,
                gems: userData["gems"] as? Int ?? 0
            )
            
            // ✅ Firestore에서 collectedVideos & playlists 가져와서 UserDefaults에 저장
            async let collectedVideos = fetchCollectedVideos(userRef: userRef)
            async let playlists = fetchPlaylists(userRef: userRef)
            
            let userCollectedVideos = await collectedVideos
            let userPlaylists = await playlists
            
            UserDefaults.standard.saveCollectedVideos(userCollectedVideos) // ✅ UserDefaults에 저장
            UserDefaults.standard.savePlaylists(userPlaylists) // ✅ UserDefaults에 저장
            
            return user
            
        } catch {
            print("❌ Firestore에서 유저 데이터 불러오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // ✅ Firestore에서 `collectedVideos` 서브컬렉션 가져오기
    private func fetchCollectedVideos(userRef: DocumentReference) async -> [CollectedVideo] {
        do {
            let snapshot = try await userRef.collection("collectedVideos").getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: CollectedVideo.self) }
        } catch {
            print("❌ collectedVideos 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    // ✅ Firestore에서 `playlists` 서브컬렉션 가져오기
    private func fetchPlaylists(userRef: DocumentReference) async -> [Playlist] {
        do {
            let snapshot = try await userRef.collection("playlists").getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Playlist.self) }
        } catch {
            print("❌ playlists 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    private func saveUserToFirestore(uid: String, userData: User) async {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        let userDataToSave: [String: Any] = [
            "id": uid,
            "email": userData.email,
            "nickname": userData.nickname,
            "profileImageURL": userData.profileImageURL ?? "",
            "bio": userData.bio ?? "",
            "experience": userData.experience,
            "balance": userData.balance,
            "gems": userData.gems
        ]
        
        do {
            // ✅ 1. 유저 문서 먼저 저장
            try await userRef.setData(userDataToSave)
            print("🔥 Firestore에 새로운 유저 저장 완료! ID: \(uid)")
            
        } catch {
            print("❌ Firestore 저장 오류: \(error.localizedDescription)")
        }
    }
    
    // ✅ 로그아웃 기능 (UserDefaults 초기화 포함)
    func signOut() {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "currentUser")
            DispatchQueue.main.async {
                self.isUserInitialized = false
                self.userService.user = nil
            }
            print("✅ 로그아웃 완료. UserDefaults 초기화됨.")
        } catch {
            print("❌ 로그아웃 실패: \(error.localizedDescription)")
        }
    }
    
    // ✅ 회원탈퇴 기능 (Firestore 및 Firebase Auth에서 계정 삭제)
    func deleteAccount() async {
        guard let user = Auth.auth().currentUser else {
            print("❌ 현재 로그인된 유저가 없습니다.")
            return
        }
        
        let uid = user.uid
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        do {
            // ✅ 1. Firestore에서 유저 데이터 삭제
            try await userRef.delete()
            print("🔥 Firestore에서 유저 데이터 삭제 완료")
            
            // ✅ 2. Firestore의 `collectedVideos` 서브컬렉션 삭제
            let collectedVideosRef = userRef.collection("collectedVideos")
            let collectedVideos = try await collectedVideosRef.getDocuments()
            for document in collectedVideos.documents {
                try await document.reference.delete()
            }
            print("🔥 Firestore에서 collectedVideos 삭제 완료")
            
            // ✅ 3. Firestore의 `playlists` 서브컬렉션 삭제
            let playlistsRef = userRef.collection("playlists")
            let playlists = try await playlistsRef.getDocuments()
            for document in playlists.documents {
                try await document.reference.delete()
            }
            print("🔥 Firestore에서 playlists 삭제 완료")
            
            // ✅ 4. Firebase Auth에서 유저 계정 삭제
            try await user.delete()
            print("🔥 Firebase Authentication에서 계정 삭제 완료")
            
            // ✅ 5. 로그아웃 및 UserDefaults 초기화
            signOut()
            
            print("✅ 회원탈퇴 완료")
            
        } catch {
            print("❌ 회원탈퇴 실패: \(error.localizedDescription)")
        }
    }
    
    
    // ✅ Nonce 관련 함수
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                return random
            }
            
            randoms.forEach { byte in
                if remainingLength == 0 { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }
    
    func waitForDataSync() async {
        // ✅ Firestore 데이터 동기화 (비동기 작업이므로 Task.sleep 사용)
        do {
            print("🕒 Firestore 데이터 동기화 중...")
            
            // ✅ 1. Firestore에서 collectedVideos 가져오기
            await CollectionService.shared.syncCollectedVideosWithFirestore()
            
            // ✅ 2. Firestore에서 playlists 가져오기
            await PlaylistService.shared.syncPlaylistsWithFirestore()
            
            // ✅ 데이터가 다 불러와질 때까지 0.5초 대기
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
            print("✅ Firestore 데이터 동기화 완료!")
        } catch {
            print("❌ Firestore 데이터 동기화 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
}
