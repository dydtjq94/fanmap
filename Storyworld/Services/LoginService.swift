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
                signInWithApple(credential: appleIDCredential)
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
        }
    }

    // ✅ Apple 로그인 후 Firebase Auth 연동
    private func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let nonce = currentNonce, let appleIDToken = credential.identityToken else {
            print("Invalid login request.")
            return
        }
        
        let idTokenString = String(data: appleIDToken, encoding: .utf8)
        let firebaseCredential = OAuthProvider.credential(
            withProviderID: "apple.com",
            idToken: idTokenString ?? "",
            rawNonce: nonce
        )

        Auth.auth().signIn(with: firebaseCredential) { authResult, error in
            if let error = error {
                print("Error signing in with Apple: \(error.localizedDescription)")
                return
            }
            
            if let user = authResult?.user {
                let uid = user.uid
                let email = user.email ?? "unknown@apple.com" // ✅ 이메일 저장 (Apple 로그인 시 이메일 제공 안 될 수도 있음)
                let nickname = credential.fullName?.givenName ?? "User \(Int.random(in: 1000...9999))"
                
                self.handleLoginSuccess(uid: uid, email: email, nickname: nickname)
            }
        }
    }

    // ✅ 로그인 성공 후 Firestore → UserDefaults 저장
    private func handleLoginSuccess(uid: String, email: String, nickname: String) {
        fetchUserData(uid: uid) { existingUser in
            if let existingUser = existingUser {
                // ✅ 기존 유저가 있으면 UserDefaults에 저장
                print("✅ 기존 유저 Firestore에서 불러옴: \(existingUser.nickname)")
                self.userService.saveUser(existingUser)
            } else {
                // ✅ Firestore에 유저 정보가 없으면 새로 생성 후 저장
                print("🆕 신규 유저 생성 및 저장")
                let newUser = User(
                    id: UUID(),
                    email: email, // ✅ 이메일 추가
                    nickname: nickname,
                    profileImageURL: nil,
                    bio: "소개글을 작성하세요",
                    experience: 0,
                    balance: 1000,
                    gems: 0,
                    collectedVideos: [],
                    playlists: []
                )
                self.saveUserToFirestore(uid: uid, userData: newUser)
                self.userService.saveUser(newUser)
            }
            DispatchQueue.main.async {
                self.isUserInitialized = true
            }
        }
    }

    // ✅ Firestore에서 유저 정보 가져오기
    private func fetchUserData(uid: String, completion: @escaping (User?) -> Void) {
        let db = Firestore.firestore()
        db.collection("users").document(uid).getDocument { document, error in
            guard let document = document, document.exists else {
                completion(nil)
                return
            }

            do {
                let user = try document.data(as: User.self)
                completion(user)
            } catch {
                print("Error decoding user: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    // ✅ Firestore에 유저 정보 저장
    private func saveUserToFirestore(uid: String, userData: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        do {
            try userRef.setData(from: userData)
            print("🔥 Firestore에 새로운 유저 저장 완료!")
        } catch {
            print("Error saving user data: \(error.localizedDescription)")
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
            print("Error signing out: \(error.localizedDescription)")
        }
    }

    // ✅ Nonce 관련 함수
    private func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
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
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
