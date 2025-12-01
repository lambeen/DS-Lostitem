import SwiftUI

struct Notice_View: View {

    @Environment(\.dismiss) private var dismiss

    private let accent = Color(red: 0.78, green: 0.10, blue: 0.36)

    var body: some View {
        VStack(spacing: 0) {
            
            
            // 리스트 본문
            List {
                NavigationLink {
                    NoticeDetail_View(noticeId: 1)
                        .duksungHeaderNav(
                            title: "유실물 센터 안내 (필수 확인)",
                            showSearch: true,
                            hideBackButton: false
                        )
                } label: {
                    Text("유실물 센터 안내 (필수 확인)")
                }

                NavigationLink {
                    NoticeDetail_View(noticeId: 1)
                } label: {
                    Text("추석 연휴 안내")
                }
            }
            .listStyle(.plain)
        }
        .duksungHeaderNav(
            title: "공지사항",
            showSearch: true,
            hideBackButton: false
        )
    }
}

#Preview {
    NavigationStack { Notice_View() }
}
