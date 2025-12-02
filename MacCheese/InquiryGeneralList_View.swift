import SwiftUI

struct InquiryGeneralList_View: View {
    
    @StateObject var store = InquiryStore()  // store 생성
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    Text("내 일반 문의")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 26)
                        .background(Color(red: 137/255, green: 20/255, blue: 43/255))
                    
                    List {
                        ForEach(store.inquiries, id: \.self) { title in
                            NavigationLink(destination: InquiryGeneralContent_View()) {
                                HStack {
                                    Text(title)
                                        .foregroundColor(.black)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 6)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
                
                NavigationLink(destination: NewInquiry_View(store: store)) {
                    Text("문의하기")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(Color(red: 137/255, green: 20/255, blue: 43/255))
                }
            }
        }
    }
}

#Preview {
    InquiryGeneralList_View()
}
