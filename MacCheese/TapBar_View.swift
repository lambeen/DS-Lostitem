import SwiftUI

struct TapBar_View: View {
    @EnvironmentObject var globalTimer: GlobalTimer
    @StateObject private var auctionMonitor = AuctionMonitor.shared
    
    let userPkey: Int
    
    @State private var navigationPath = NavigationPath()
    @State private var shouldShowEnded = false
    @State private var endedAuctionId = 0
    
    var body: some View {
        TabView {
            NavigationStack(path: $navigationPath) {
                LostItemList_View(userPkey: userPkey)
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "shippingbox.fill")
                        .font(.system(size: 20))
                    Text("분실물")
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            NavigationStack(path: $navigationPath) {
                AuctionList_View()
                    .environmentObject(globalTimer)
            }
            .tabItem {
                VStack(spacing: 2) {
                    Image(systemName: "banknote.fill")
                        .font(.system(size: 20))
                    Text("경매")
                        .font(.system(size: 13, weight: .semibold))
                }
            }

            NavigationStack(path: $navigationPath) {
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

            NavigationStack(path: $navigationPath) {
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
        .accentColor(accent)
        .toolbarBackground(.white, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("AuctionEndedForWinner"))) { noti in
            if let id = noti.userInfo?["auctionId"] as? Int {
                endedAuctionId = id
                shouldShowEnded = true
            }
        }
        .sheet(isPresented: $shouldShowEnded) {
            NavigationStack {
                AuctionEnded_View(auctionId: endedAuctionId)
                    .environmentObject(globalTimer)
            }
        }
    }
}

#Preview {
    TapBar_View(userPkey: 1)
}
