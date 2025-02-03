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

    // ✅ Apple 로그인 버튼 요청 처리 (Nonce 생성)
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
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
                let nickname = credential.fullName?.givenName ?? "사용자\(Int.random(in: 1000...9999))"
                
                let userData = User(
                    id: UUID(),
                    nickname: nickname,
                    profileImageURL: nil,
                    bio: nil,
                    experience: 0,
                    balance: 0,
                    gems: 0,
                    collectedVideos: [],
                    playlists: []
                )

                self.saveUserToFirestore(uid: uid, userData: userData)
            }
        }
    }

    // ✅ Firestore에 유저 정보 저장
    private func saveUserToFirestore(uid: String, userData: User) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                print("User already exists in Firestore.")
            } else {
                do {
                    try userRef.setData(from: userData)
                    print("New user added to Firestore!")
                    DispatchQueue.main.async {
                        self.isUserInitialized = true
                    }
                } catch {
                    print("Error saving user data: \(error.localizedDescription)")
                }
            }
        }
    }

    // ✅ Firestore에서 유저 정보 가져오기
    func fetchUserData(uid: String, completion: @escaping (User?) -> Void) {
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

    // ✅ 로그아웃 기능
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.isUserInitialized = false
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
