import SwiftUI

class InquiryStore: ObservableObject {
    @Published var inquiries: [String] = [
        "분실물 언제까지 가지러 ...",
        "분실물은 언제까지 찾을 수...",
        "경매 낙찰 관련 질문인데요...",
        "앱이 자꾸 렉이 걸리는데..."
    ]
    
    func addInquiry(title: String) {
        inquiries.insert(title, at: 0)
    }
}

