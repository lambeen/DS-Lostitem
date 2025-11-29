//
//  Settings_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//
//

import SwiftUI

struct Settings_View: View {

    @State private var showLogin = false
    @AppStorage("studentId") private var storedStudentId: String = ""
    
    
    var body: some View {
        VStack {
            List {
                // 🔹 현재 로그인 정보 (학번 표시)
                Section {
                    HStack {
                        Text("학번")
                        Spacer()
                        Text(storedStudentId.isEmpty ? " " : storedStudentId)
                            .foregroundColor(.secondary)
                    }
                }
                // 🔹 로그아웃 섹션
                Section {
                    Button("로그아웃") {
                        showLogin = true
                    }
                }

                // 🔹 설정 메뉴 섹션
                Section {
                    NavigationLink("내 댓글") {
                        MyComments_View(userPkey: 1)
                    }

                    NavigationLink("개인정보처리방침/이용약관") {
                        Terms_View()
                    }

                    NavigationLink("문의하기") {
                        Inquiry_View()
                    }

                    NavigationLink("공지사항") {
                        Notice_View()
                    }
                }
            }
            .fullScreenCover(isPresented: $showLogin) {
                Login_View()
            }
        }
        .duksungHeaderNav(
            title: "설정",
            showSearch: false,
            hideBackButton: true
        )
    }
}

#Preview {
    NavigationStack {
        Settings_View()
    }
}
