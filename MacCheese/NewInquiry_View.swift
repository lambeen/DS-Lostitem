import SwiftUI

struct NewInquiry_View: View {
    
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: InquiryStore  // store 필수
    
    @State private var titleText: String = ""
    @State private var contentText: String = ""
    
    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)
    
    var body: some View {
        VStack(spacing: 0) {
            // 상단 헤더
            HStack(spacing: 12) {
                Button { dismiss() } label: {
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
                    VStack(alignment: .leading, spacing: 4) {
                        Text("제목")
                        TextField("제목을 입력하세요..", text: $titleText)
                            .padding(8)
                            .background(accent)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("내용")
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
                
                Button {
                    if !titleText.isEmpty {
                        store.addInquiry(title: titleText)
                    }
                    dismiss()
                } label: {
                    HStack {
                        Text("제출하기")
                        Image(systemName: "arrow.right")
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(accent)
                    .cornerRadius(6)
                }
                .padding(.top, 16)
                
                Text("befanyelse@gmail.com")
                    .font(.footnote)
                    .foregroundColor(.primary)
                    .padding(.top, 12)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    NavigationStack {
        NewInquiry_View(store: InquiryStore())  // Preview용 store 전달
    }
}

