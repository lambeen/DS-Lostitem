import SwiftUI
import Combine

@MainActor
final class AuctionMonitor: ObservableObject {
    static let shared = AuctionMonitor()
    
    @Published var shouldNavigateToEnded: (auctionId: Int, shouldNavigate: Bool) = (0, false)
    
    private var cancellables = Set<AnyCancellable>()
    private var monitoredAuctions: Set<Int> = []
    private var checkedAuctions: Set<Int> = []
    
    private var storedStudentId: String {
        UserDefaults.standard.string(forKey: "studentId") ?? ""
    }
    
    private init() {
        setupTimer()
    }
    
    func startMonitoring(auctionId: Int) {
        monitoredAuctions.insert(auctionId)
        checkedAuctions.remove(auctionId)
    }
    
    func startMonitoring(auctionIds: [Int]) {
        auctionIds.forEach { id in
            monitoredAuctions.insert(id)
            checkedAuctions.remove(id)
        }
    }
    
    func stopMonitoring(auctionId: Int) {
        monitoredAuctions.remove(auctionId)
        checkedAuctions.remove(auctionId)
    }
    
    func stopAllMonitoring() {
        monitoredAuctions.removeAll()
        checkedAuctions.removeAll()
    }
    
    private func setupTimer() {
        Timer.publish(every: 5.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkAuctions()
            }
            .store(in: &cancellables)
    }
    
    private func checkAuctions() {
        if monitoredAuctions.isEmpty { return }
        
        for id in monitoredAuctions {
            if checkedAuctions.contains(id) { continue }
            checkAuction(auctionId: id)
        }
    }
    
    private func checkAuction(auctionId: Int) {
        let group = DispatchGroup()
        var detail: AuctionItemDetailDTO?
        var bids: [BidRank] = []
        
        group.enter()
        guard let detailURL = URL(string: "\(API.auctionItemDetail)?auction_id=\(auctionId)") else {
            group.leave()
            return
        }
        
        URLSession.shared.dataTask(with: detailURL) { data, _, _ in
            if let data = data {
                detail = try? JSONDecoder().decode(AuctionItemDetailDTO.self, from: data)
            }
            group.leave()
        }.resume()
        
        group.enter()
        guard let bidsURL = URL(string: "\(API.auctionBids)?auction_id=\(auctionId)") else {
            group.leave()
            return
        }
        
        URLSession.shared.dataTask(with: bidsURL) { data, _, _ in
            if let data = data, let decoded = try? JSONDecoder().decode(AuctionBidsResponseDTO.self, from: data) {
                bids = decoded.bids
            }
            group.leave()
        }.resume()
        
        group.notify(queue: .main) {
            guard let detail = detail else { return }
            
            let isEnded = detail.statusCode == 3 || detail.statusCode == 4 || detail.timeLeftSeconds <= 0
            if isEnded {
                let sorted = bids.sorted { $0.rank < $1.rank }
                if let winner = sorted.first, winner.studentId == self.storedStudentId {
                    self.checkedAuctions.insert(auctionId)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("AuctionEndedForWinner"),
                        object: nil,
                        userInfo: ["auctionId": auctionId]
                    )
                }
            }
        }
    }
}

