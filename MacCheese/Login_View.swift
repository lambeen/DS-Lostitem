//
//  Login_View.swift
//  MacCheese
//
//  Created by mac10 on 10/27/25.
//  Updated to real login form
//

import SwiftUI

struct Login_View: View {
    @State private var studentId: String = ""       // 학번
    @State private var password: String = ""        // 비밀번호
    @State private var message: String? = nil       // 안내/에러 메시지
    @State private var succeedLogin: Bool = false   // 로그인 성공 플래그
    @State private var succeedSignup: Bool = false  // 회원가입 화면 이동 플래그
    
    // 로그인 성공 시 저장할 학번 (전역 공유용)
    @AppStorage("studentId") private var storedStudentId: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()   // 🔹 위쪽 여백 → 전체를 가운데로

                // ✅ 로그인 카드 전체
                VStack(spacing: 25) {
                    
                    Image("ds_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                    
                    // 앱 이름 뱃지
                    Text("분실물은 덕새를 타고")
                        .font(.title.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(accent)
                        .foregroundColor(.white)
                        .cornerRadius(12)

                    // 로그인 타이틀
                    Text("로그인")
                        .font(.largeTitle.bold())
                        .frame(maxWidth: .infinity, alignment: .leading)

                    // 학번 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("학번")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("학번을 입력하세요", text: $studentId)
                            .keyboardType(.numberPad)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 비밀번호 입력
                    VStack(alignment: .leading, spacing: 8) {
                        Text("비밀번호")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        SecureField("비밀번호를 입력하세요", text: $password)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 메시지
                    if let message {
                        Text(message)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // 로그인 이동용
                    NavigationLink(
                        destination: TapBar_View(userPkey: 1),
                        isActive: $succeedLogin
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    // 로그인 버튼
                    Button {
                        login()
                    } label: {
                        Text("로그인")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 150)
                            .padding()
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .submitScope(true)

                    // 회원가입 이동
                    NavigationLink(
                        destination: Signup_View(),
                        isActive: $succeedSignup
                    ) {
                        EmptyView()
                    }
                    .hidden()

                    // 회원가입 버튼
                    Button {
                        signup()
                    } label: {
                        Text("회원가입 하러 가기")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 150)
                            .padding()
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // 로그인 처리함수
    private func login() {
        // 공백 체크
        guard !studentId.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "학번을 입력하시오"
            return
        }
        
        guard !password.isEmpty else {
            message = "비밀번호를 입력하시오"
            return
        }

        guard password.count >= 4 else {
            message = "비밀번호는 4자 이상이어야 합니다."
            return
        }

        // 학생 검증(학생은 20으로 시작하는 숫자 8자리, 관리자 검증(관리자는 9999로 시작하는 8자리)
        let isAdmin = studentId.hasPrefix("9999")
        let pattern = #"^(20\d{6}|9999\d{4})$"#

        guard studentId.range(of: pattern, options: .regularExpression) != nil else {
            message = "학번은 '20'으로 시작하는 8자리 숫자여야 합니다.\n(관리자는 9999로 시작하는 8자리 숫자)"
            return
        }

        if isAdmin {
            print("관리자 계정으로 로그인 시도")
        }

    // 서버연동
        guard let url = URL(string: API.login) else {
            message = "서버 주소가 잘못되었습니다."
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        // PHP에서 $_POST['studentId'], $_POST['password'], $_POST['is_admin'] 로 받는다고 가정
        let params: [String: String] = [
            "studentId": studentId,
            "password": password,
            "is_admin": isAdmin ? "1" : "0"
        ]

        // application/x-www-form-urlencoded 형태로 바디 만들기
        let bodyString = params
            .map { key, value in
                let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(key)=\(encoded)"
            }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)
        request.setValue(
            "application/x-www-form-urlencoded",
            forHTTPHeaderField: "Content-Type"
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
            
            // 네트워크 에러
            if let error = error {
                DispatchQueue.main.async {
                    self.message = "네트워크 오류: \(error.localizedDescription)"
                }
                return
            }

            // 데이터 없음
            guard let data = data else {
                DispatchQueue.main.async {
                    self.message = "서버 응답이 없습니다!"
                }
                return
            }

            // 서버에서 온 문자열
            let text = String(data: data, encoding: .utf8) ?? ""
            print("LoginV.php 응답:", text)

            // 앞뒤 공백/줄바꿈 제거
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

            DispatchQueue.main.async {
                if trimmed == "1" {
                    // 로그인 성공
                    self.message = nil
                    
                    //학번 저장 → Settings_View
                    self.storedStudentId = self.studentId
                    
                    
                    self.succeedLogin = true
                } else {
                    // 실패
                    self.message = trimmed.isEmpty ? "로그인에 실패했습니다." : trimmed
                }
            }
        }.resume()
    }

    // 회원가입 버튼 눌렀을 때
    private func signup() {
        succeedSignup = true
    }
}

#Preview {
    Login_View()
}
