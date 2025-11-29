//
//  Signup_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//

import SwiftUI

struct Signup_View: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var studentId: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var message: String? = nil
    @State private var showSuccess: Bool = false
    
    var body: some View {
        VStack(spacing: 28) {
            
            Text("회원가입")
                .font(.largeTitle).bold()
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // 이름
            InputSection(title: "이름을 입력하시오") {
                TextField("이름", text: $name)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 학번
            InputSection(title: "학번을 입력하시오") {
                TextField("학번", text: $studentId)
                    .keyboardType(.numberPad)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 이메일
            InputSection(title: "이메일을 입력하시오") {
                TextField("이메일", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 비밀번호
            InputSection(title: "비밀번호를 입력하시오") {
                SecureField("비밀번호", text: $password)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 비밀번호 확인
            InputSection(title: "비밀번호를 한 번 더 입력하시오") {
                SecureField("비밀번호 확인", text: $confirmPassword)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled(true)
                    .textFieldStyle(.roundedBorder)
            }
            
            // 메시지
            if let message {
                Text(message)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            // 회원가입 버튼
            Button {
                signup()
            } label: {
                Text("회원가입")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accent)   // 공통 색상 쓰고 있으면 accent 사용
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // 로그인 이동
            NavigationLink(destination: Login_View()) {
                VStack(spacing: 2) {
                    Text("로그인하시겠습니까?")
                        .foregroundColor(.secondary)
                    Text("로그인하러가기")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .underline()
                }
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .alert("회원가입 완료", isPresented: $showSuccess) {
            Button("확인") { dismiss() }
        } message: {
            Text("회원가입이 완료되었습니다.")
        }
    }
    
    // 회원가입 처리
    private func signup() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "이름을 입력하시오"; return
        }
        guard !studentId.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "학번을 입력하시오"; return
        }
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "이메일을 입력하시오"; return
        }
        guard !password.isEmpty else {
            message = "비밀번호를 입력하시오"; return
        }
        guard !confirmPassword.isEmpty else {
            message = "비밀번호를 한 번 더 입력하시오"; return
        }
        
        if studentId.range(of: #"^[0-9]{4,}$"#, options: .regularExpression) == nil {
            message = "학번은 숫자 4자리 이상이어야 합니다."
            return
        }
        if email.range(of: #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#,
                       options: [.regularExpression, .caseInsensitive]) == nil {
            message = "이메일 형식을 확인하시오"
            return
        }
        guard password == confirmPassword else {
            message = "비밀번호가 일치하지 않습니다."
            return
        }
        
        message = nil
        
       
        guard let url = URL(string: API.signup) else {
            message = "서버 주소가 올바르지 않습니다."
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let bodyString =
            "name=\(name)&id=\(studentId)&email=\(email)&pwd=\(password)"
        
        request.httpBody = bodyString.data(using: .utf8)
        request.setValue(
            "application/x-www-form-urlencoded; charset=utf-8",
            forHTTPHeaderField: "Content-Type"
        )
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data,
                  let result = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) else {
                DispatchQueue.main.async { self.message = "서버 응답 오류" }
                return
            }
            
            DispatchQueue.main.async {
                if result == "success" {
                    self.showSuccess = true
                } else {
                    self.message = "회원가입 실패: \(result)"
                }
            }
        }.resume()
    }
}

// 입력 필드 묶음
private struct InputSection<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
            content()
        }
    }
}

#Preview {
    NavigationView {
        Signup_View()
    }
}
