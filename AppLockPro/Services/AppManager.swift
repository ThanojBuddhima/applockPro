import Foundation
import Combine

/// Manages the persistence and state of protected applications.
class AppManager: ObservableObject {
    static let shared = AppManager()
    
    @Published var protectedApps: [ProtectedApp] = [] {
        didSet {
            save()
        }
    }
    
    private let defaultsKey = "FaceLockPro_ProtectedApps"
    
    private init() {
        load()
    }
    
    /// Adds an app to the protected list if it's not already there.
    func addApp(_ app: ProtectedApp) {
        if !protectedApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) {
            protectedApps.append(app)
        }
    }
    
    /// Removes an app from the protected list.
    func removeApp(bundleIdentifier: String) {
        protectedApps.removeAll { $0.bundleIdentifier == bundleIdentifier }
    }
    
    /// Checks if a specific bundle identifier is currently protected.
    func isAppProtected(bundleIdentifier: String) -> Bool {
        guard let app = protectedApps.first(where: { $0.bundleIdentifier == bundleIdentifier }) else {
            return false
        }
        return app.isProtected
    }
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(protectedApps)
            UserDefaults.standard.set(data, forKey: defaultsKey)
        } catch {
            print("Failed to save protected apps: \(error)")
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        do {
            let apps = try JSONDecoder().decode([ProtectedApp].self, from: data)
            self.protectedApps = apps
        } catch {
            print("Failed to load protected apps: \(error)")
        }
    }
}
