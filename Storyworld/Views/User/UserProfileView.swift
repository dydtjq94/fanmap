//
//  UserProfileView.swift
//  Storyworld
//
//  Created by peter on 1/24/25.
//

import SwiftUI
import PhotosUI
import AVFoundation
import Photos

struct UserProfileView: View {
    @EnvironmentObject var userService: UserService
    
    @State private var isEditingNickname = false
    @State private var isEditingBio = false
    @State private var editedNickname = ""
    @State private var editedBio = ""
    
    @State private var isShowingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var selectedSourceType: UIImagePickerController.SourceType?
    
    // ✅ 업로드 중인지 표시하는 변수
    @State private var isUploadingProfileImage = false
    
    @State private var profileImage: UIImage? = nil
    
    var body: some View {
        if userService.user != nil {
            HStack(alignment: .center, spacing: 16) {
                
                // 프로필 이미지 & 로딩 표시 ZStack
                ZStack {
                    // 원래 버튼
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        checkPermission(for: .photoLibrary) { granted in
                            if granted {
                                DispatchQueue.main.async {
                                    selectedSourceType = .photoLibrary
                                    isShowingImagePicker = true
                                }
                            } else {
                                print("❌ Photo Library 권한 거부됨")
                            }
                        }
                    }) {
                        if let image = profileImage {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        } else {
                            Image("default_user_image1")
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                    }
                    
                    // ✅ 업로드 중이면, Circle 위에 로딩 아이콘 표시
                    if isUploadingProfileImage {
                        Circle()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.black.opacity(0.3))
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                }
                
                // 나머지 UI (닉네임, 배지 등)
                VStack(alignment: .leading) {
                    // 닉네임 수정 버튼
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        editedNickname = userService.user?.nickname ?? "Guest"
                        isEditingNickname = true
                    }) {
                        Text(userService.user?.nickname ?? "Guest")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.bottom, 2)
                    
                    // 기존 Badge UI
                    HStack(spacing: 8) {
                        HStack(spacing: 2) {
                            Image(systemName: "arrow.up.square.fill")
                                .foregroundColor(Color(AppColors.mainColor))
                                .font(.system(size: 12))
                            
                            Text("Lv. \(UserStatusManager.shared.calculateLevel(from: userService.user?.experience ?? 0))")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "film.stack.fill")
                                .foregroundColor(Color(AppColors.green1))
                                .font(.system(size: 12))
                            
                            Text("\(UserDefaults.standard.loadCollectedVideos().count)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "inset.filled.diamond")
                                .foregroundColor(Color(UIColor(hex: "#00FFFF")))
                                .font(.system(size: 12))
                            Text("\(userService.user?.gems ?? 0)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        HStack(spacing: 2) {
                            Image(systemName: "dollarsign.circle.fill")
                                .foregroundColor(Color(UIColor(hex: "#FFD700")))
                                .font(.system(size: 12))
                            Text("\(userService.user?.balance ?? 0)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(Color(UIColor(hex: "#7E7E7E")))
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, 4)
                    
                    // 소개글 수정 버튼
                    Button(action: {
                        UIImpactFeedbackGenerator.trigger(.light)
                        editedBio = userService.user?.bio ?? "소개글을 입력하세요"
                        isEditingBio = true
                    }) {
                        Text(userService.user?.bio?.isEmpty == false ? userService.user!.bio! : "소개글을 입력하세요")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            // 닉네임 수정 Alert
            .alert("닉네임 수정", isPresented: $isEditingNickname) {
                VStack {
                    TextField("닉네임을 입력하세요", text: $editedNickname)
                        .onChange(of: editedNickname) {
                            if editedNickname.count > 12 {
                                editedNickname = String(editedNickname.prefix(12))
                            }
                        }
                    
                    HStack {
                        Button("취소", role: .cancel) {
                            isEditingNickname = false
                        }
                        Button("저장") {
                            if var user = userService.user {
                                user.nickname = editedNickname
                                userService.saveUser(user)
                            }
                            isEditingNickname = false
                        }
                    }
                }
            }
            .onAppear {
                // 1) 로컬 파일 먼저 확인
                if let localImage = userService.loadProfileImageLocally() {
                    self.profileImage = localImage
                    print("✅ 로컬 이미지를 즉시 UI에 반영")
                } else {
                    // 2) 로컬에 없으면 서버에서 로드
                    userService.loadProfileImage { image in
                        self.profileImage = image
                    }
                }
            }
            .onChange(of: userService.user?.profileImageURL) {
                // 서버 URL이 바뀌면, 혹시 모르니 다시 서버 로드 (or 로컬 저장)?
                userService.loadProfileImage { image in
                    self.profileImage = image
                }
            }
            .sheet(isPresented: $isShowingImagePicker, onDismiss: handleImageSelection) {
                ImagePickerManager(image: $selectedImage, sourceType: .photoLibrary)
            }
        } else {
            ProgressView("Loading user data...")
                .padding()
        }
    }
    
    // 이미지 선택 후 업로드 로직
    private func handleImageSelection() {
        guard let selectedImage = selectedImage else { return }
        
        // 1) 화면에 즉시 반영
        self.profileImage = selectedImage
        
        // 2) 로컬에 저장
        userService.saveProfileImageLocally(selectedImage)
        
        // 3) 업로드
        isUploadingProfileImage = true
        userService.uploadProfileImage(selectedImage) { url in
            isUploadingProfileImage = false
            
            if let url = url {
                userService.updateProfileImageURL(imageURL: url)
            }
        }
    }
}
