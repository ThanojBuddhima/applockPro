import Foundation
import Combine
import AppKit
import SwiftUI

/// Manages the global authentication session state.
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var isSessionActive: Bool = false
    
    private var lastAuthDate: Date? {
        didSet {
            updateSessionState()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var timer: Timer?
    
    // Read settings from AppStorage equivalent
    @AppStorage("sessionTimeout") private var sessionTimeoutRaw = AppSettings.SessionTimeout.thirtyMinutes.rawValue
    @AppStorage("lockAfterSleep") private var lockAfterSleep = true
    
    private var sessionTimeoutInterval: TimeInterval {
        let timeout = AppSettings.SessionTimeout(rawValue: sessionTimeoutRaw) ?? .always
        // For "Always Authenticate" (0 seconds), session is never active
        // For "Until Logout" (nil seconds), use a very large value
        if let seconds = timeout.seconds {
            return seconds
        } else {
            return Double.greatestFiniteMagnitude // "Until Logout" — effectively infinite
        }
    }
    
    private init() {
        // Observe workspace sleep/wake if lockAfterSleep is true
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.willSleepNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.lockAfterSleep {
                    self.invalidateSession()
                }
            }
            .store(in: &cancellables)
            
        // Start a timer to periodically check if the session expired
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateSessionState()
        }
    }
    
    /// Called when the user successfully authenticates
    func activateSession() {
        lastAuthDate = Date()
    }
    
    /// Forces the session to invalidate
    func invalidateSession() {
        lastAuthDate = nil
    }
    
    private func updateSessionState() {
        guard let lastAuth = lastAuthDate else {
            if isSessionActive {
                isSessionActive = false
            }
            return
        }
        
        let elapsed = Date().timeIntervalSince(lastAuth)
        let isActive = elapsed < sessionTimeoutInterval
        
        if isSessionActive != isActive {
            isSessionActive = isActive
        }
        
        if !isActive {
            lastAuthDate = nil // Clear it out once expired
        }
    }
}
