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
import FirebaseFunctions
import CryptoKit

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
    
    // MARK: - Apple 로그인 후 Firebase Auth 연동 (async)
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) async {
        guard let nonce = currentNonce, let appleIDToken = credential.identityToken else {
            print("❌ Invalid login request.")
            return
        }
        
        let idTokenString = String(data: appleIDToken, encoding: .utf8)
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString ?? "",
            rawNonce: nonce
        )
        
        do {
            let authResult = try await Auth.auth().signIn(with: firebaseCredential)
            let user = authResult.user
            let uid = user.uid
            let email = user.email ?? "unknown@apple.com" // Apple 로그인 시 이메일이 없을 수도 있음
            let nickname = credential.fullName?.givenName ?? "User \(Int.random(in: 1000...9999))"
            
            // 로그인 성공 후, 클라우드 펑션으로 유저 생성
            await handleLoginSuccess(uid: uid, email: email, nickname: nickname)
        } catch {
            print("❌ Firebase Apple 로그인 실패: \(error.localizedDescription)")
        }
    }
    
    // LoginService.swift (간소화 예시)
    private func handleLoginSuccess(uid: String, email: String, nickname: String) async {
        let functions = Functions.functions()

        do {
            // Cloud Function 'createUserProfile'로 신규 가입 처리
            let result = try await functions.httpsCallable("createUserProfile").call([
                "email": email,
                "nickname": nickname
            ])
            if let data = result.data as? [String: Any],
               let success = data["success"] as? Bool, success {
                // 🔥 성공적으로 Firestore에 새 유저 생성
                print("🔥 Cloud Function에서 유저 생성 완료: \(nickname)")

                // ✅ 이제 UserService에 저장 (로컬)
                let user = User(
                    id: uid,
                    email: email,
                    nickname: nickname,
                    profileImageURL: nil,
                    bio: "소개글을 작성하세요",
                    experience: 0,
                    balance: 1000,
                    gems: 0
                )
                UserService.shared.saveUser(user)

                DispatchQueue.main.async {
                    self.isUserInitialized = true
                }
            }
        } catch {
            print("❌ Cloud Function 호출 오류: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Firestore에서 유저 정보 가져오기 (직접 읽기)
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
            
            // 서브컬렉션도 함께 가져오고 UserDefaults에 저장
            async let collectedVideos = fetchCollectedVideos(userRef: userRef)
            async let playlists = fetchPlaylists(userRef: userRef)
            
            let userCollectedVideos = await collectedVideos
            let userPlaylists = await playlists
            
            UserDefaults.standard.saveCollectedVideos(userCollectedVideos)
            UserDefaults.standard.savePlaylists(userPlaylists)
            
            return user
            
        } catch {
            print("❌ Firestore에서 유저 데이터 불러오기 실패: \(error.localizedDescription)")
            return nil
        }
    }
    
    
    // MARK: - Firestore에서 서브컬렉션 가져오기
    private func fetchCollectedVideos(userRef: DocumentReference) async -> [CollectedVideo] {
        do {
            let snapshot = try await userRef.collection("collectedVideos").getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: CollectedVideo.self) }
        } catch {
            print("❌ collectedVideos 불러오기 실패: \(error.localizedDescription)")
            return []
        }
    }
    
    private func fetchPlaylists(userRef: DocumentReference) async -> [Playlist] {
        do {
            let snapshot = try await userRef.collection("playlists").getDocuments()
            return snapshot.documents.compactMap { try? $0.data(as: Playlist.self) }
        } catch {
            print("❌ playlists 불러오기 실패: \(error.localizedDescription)")
            return []
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
    
    // MARK: - Firestore 데이터 동기화
    func waitForDataSync() async {
        do {
            print("🕒 Firestore 데이터 동기화 중...")
            
            // 1. Firestore에서 collectedVideos 가져오기
            await CollectionService.shared.syncCollectedVideosWithFirestore()
            
            // 2. Firestore에서 playlists 가져오기
            await PlaylistService.shared.syncPlaylistsWithFirestore()
            
            // 데이터가 다 불러와질 때까지 0.5초 대기
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5초 대기
            print("✅ Firestore 데이터 동기화 완료!")
        } catch {
            print("❌ Firestore 데이터 동기화 중 오류 발생: \(error.localizedDescription)")
        }
    }
    
}
