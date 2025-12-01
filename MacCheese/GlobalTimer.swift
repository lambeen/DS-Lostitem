import SwiftUI
import Combine

@MainActor
final class GlobalTimer: ObservableObject {
    static let shared = GlobalTimer()
    
    @Published var currentTime: Date = Date()
    
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startTimer()
        setupNotifications()
    }
    
    private func startTimer() {
        if timer != nil { return }
        
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.currentTime = Date()
            }
    }
    
    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
    private func setupNotifications() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.stopTimer()
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.currentTime = Date()
                self?.startTimer()
            }
            .store(in: &cancellables)
    }
}
