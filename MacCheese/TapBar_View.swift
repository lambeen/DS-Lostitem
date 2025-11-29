import SwiftUI

struct TapBar_View: View {
    let userPkey: Int
    
    var body: some View {
        TabView {
            // 1) 분실물
            NavigationStack {
                LostItemList_View(userPkey: userPkey)
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 20))             // 아이콘 크게
                    Text("분실물")
                        .font(.system(size: 13, weight: .semibold)) // 글씨 살짝 크게+굵게
                }
            }

            // 2) 경매
            NavigationStack {
                AuctionList_View()
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 20))
                    Text("경매")
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            // 3) 알림
            NavigationStack {
                Notification_View()
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                    Text("알림")
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            // 4) 설정
            NavigationStack {
                Settings_View()
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 20))
                    Text("설정")
                        .font(.system(size: 13, weight: .semibold))
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        // 선택된 탭 색 (네가 쓰는 accent 전역 상수)
        .accentColor(accent)
        // 탭바 배경 흰색 고정하고 싶으면
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
    }
}

#Preview {
    TapBar_View(userPkey: 1)
}
