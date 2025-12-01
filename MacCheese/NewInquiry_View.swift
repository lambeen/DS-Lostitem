import SwiftUI

struct NewInquiry_View: View {
    @State private var titleText: String = ""
    @State private var contentText: String = ""
    @State private var isSubmitted: Bool = false // 제출 여부

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    var body: some View {
        VStack(spacing: 0) {
            
            // 상단 헤더
            HStack(spacing: 12) {
                Button {
                    // 뒤로가기 액션
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                Text("문의하기")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                
            }
            
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(accent)

            ScrollView {
                VStack(spacing: 16) {
                    // 제목 입력
                    VStack(alignment: .leading, spacing: 4) {
                        Text("제목")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextField("분실물 언제까지 가지러..", text: $titleText)
                            .padding(8)
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }

                    // 내용 입력
                    VStack(alignment: .leading, spacing: 4) {
                        Text("내용")
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        TextEditor(text: $contentText)
                            .padding(8)
                            .frame(minHeight: 200)
                            .background(accent)
                            .foregroundColor(.black)
                            .cornerRadius(4)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer(minLength: 40)

                // 제출 버튼
                HStack {
                    Spacer()
                    NavigationLink(destination: InquiryUserReply_VIew(), isActive: $isSubmitted) {
                        Button {
                            // 서버 전송 로직 추가
                            print("제출됨 제목:", titleText, "내용:", contentText)
                            isSubmitted = true // 화면 이동
                        } label: {
                            HStack {
                                Text("제출하기")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Image(systemName: "arrow.right")
                                    .foregroundColor(.white)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(accent)
                            .cornerRadius(6)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                // 이메일 표시
                Text("befanyelse@gmail.com")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(.systemBackground))
        }
        .duksungHeaderNav(
                    title: "덕성여대 문의 통합포털", // 붉은 타이틀 바 텍스트
                    showSearch: false,                 // 오른쪽 검색 버튼 표시
                    hideBackButton: false             // 루트 화면이니까 뒤로가기 숨김
                )
    }
}

#Preview {
    NavigationStack {
        NewInquiry_View()
    }
}


