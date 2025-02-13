//
//  SettingsView.swift
//  Storyworld
//
//  Created by peter on 2/6/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userService: UserService
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showDeleteAlert = false
    @State private var isDeleting = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("정보")
                    .foregroundColor(Color.white) // ✅ 헤더 색상 변경
                ) {
                    Link("이용약관", destination: URL(string: "https://nmax.notion.site/18c6a17d455480c48f7decd6bc89b802?pvs=4")!)
                        .foregroundColor(.white)
                    Link("개인정보처리방침", destination: URL(string: "https://nmax.notion.site/18c6a17d4554809db4d5ca7ee4ba709f?pvs=4")!)
                        .foregroundColor(.white)
                }
                .listRowBackground(Color(UIColor(hex:"#1D1D1D"))) // ✅ Section 내부 배경 수정
                Section(header: Text("계정")
                    .foregroundColor(Color.white) // ✅ 헤더 색상 변경
                ) {
                    Button(action: {
                        LoginService.shared.signOut()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("로그아웃")
                            .foregroundColor(.red)
                    }
                    
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text("회원탈퇴")
                            .foregroundColor(.red)
                    }
                    .alert("정말로 계정을 삭제하시겠습니까?", isPresented: $showDeleteAlert) {
                        Button("취소", role: .cancel) { }
                        Button("삭제", role: .destructive) {
                            Task {
                                isDeleting = true
                                await LoginService.shared.deleteAccount()
                                isDeleting = false
                            }
                        }
                    } message: {
                        Text("회원탈퇴 시 모든 데이터가 삭제되며 복구할 수 없습니다.")
                    }
                }
                .listRowBackground(Color(UIColor(hex:"#1D1D1D"))) // ✅ Section 내부 배경 수정
            }
            .scrollContentBackground(.hidden) // ✅ 기본 배경 제거
            .background(Color(UIColor(hex:"#1D1D1D"))) // ✅ 원하는 배경색 설정
            .navigationTitle("설정")
            .listStyle(GroupedListStyle())
            .overlay(
                isDeleting ? ProgressView("삭제 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
                : nil
            )
        }
        .background(Color(UIColor(hex:"#1D1D1D"))) // ✅ NavigationView 배경도 설정
    }
}
