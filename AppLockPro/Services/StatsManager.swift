import Foundation
import Combine

/// Manages statistics for authentication attempts (successes and failures) for the current day.
class StatsManager: ObservableObject {
    static let shared = StatsManager()
    
    @Published var authSuccessToday: Int = 0
    @Published var authFailuresToday: Int = 0
    
    private let successKey = "FaceLockPro_AuthSuccessToday"
    private let failuresKey = "FaceLockPro_AuthFailuresToday"
    private let dateKey = "FaceLockPro_StatsDate"
    
    private init() {
        loadStats()
        
        // Listen for significant time change to reset stats at midnight
        NotificationCenter.default.addObserver(self, selector: #selector(checkDate), name: .NSCalendarDayChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func recordSuccess() {
        checkDate()
        authSuccessToday += 1
        saveStats()
    }
    
    func recordFailure() {
        checkDate()
        authFailuresToday += 1
        saveStats()
    }
    
    @objc private func checkDate() {
        let lastDateString = UserDefaults.standard.string(forKey: dateKey)
        let currentDateString = getCurrentDateString()
        
        if lastDateString != currentDateString {
            // New day, reset stats
            authSuccessToday = 0
            authFailuresToday = 0
            UserDefaults.standard.set(currentDateString, forKey: dateKey)
            saveStats()
        }
    }
    
    private func loadStats() {
        checkDate()
        authSuccessToday = UserDefaults.standard.integer(forKey: successKey)
        authFailuresToday = UserDefaults.standard.integer(forKey: failuresKey)
    }
    
    private func saveStats() {
        UserDefaults.standard.set(authSuccessToday, forKey: successKey)
        UserDefaults.standard.set(authFailuresToday, forKey: failuresKey)
    }
    
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
