import Foundation
import AppKit

class AppListService {
    static let shared = AppListService()
    
    private init() {}
    
    /// Fetches a list of installed applications from /Applications and /System/Applications.
    /// This method performs disk I/O and should ideally be called off the main thread.
    func fetchInstalledApps() -> [InstalledApp] {
        var apps: [InstalledApp] = []
        let urls = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications")
        ]
        
        let fileManager = FileManager.default
        let keys: [URLResourceKey] = [.isApplicationKey, .localizedNameKey]
        
        for url in urls {
            // We use skipsPackageDescendants so we don't look inside an .app bundle
            guard let enumerator = fileManager.enumerator(
                at: url,
                includingPropertiesForKeys: keys,
                options: [.skipsPackageDescendants, .skipsHiddenFiles],
                errorHandler: nil
            ) else {
                continue
            }
            
            for case let fileURL as URL in enumerator {
                // Ensure the item is an application
                guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                      let isApp = resourceValues.isApplication, isApp else {
                    continue
                }
                
                // Get bundle identifier; if it doesn't have one, it's not a standard macOS app
                guard let bundle = Bundle(url: fileURL),
                      let bundleIdentifier = bundle.bundleIdentifier else {
                    continue
                }
                
                // Exclude our own app from the list
                if bundleIdentifier == Bundle.main.bundleIdentifier {
                    continue
                }
                
                let name = resourceValues.localizedName ?? fileURL.deletingPathExtension().lastPathComponent
                let icon = NSWorkspace.shared.icon(forFile: fileURL.path)
                
                let app = InstalledApp(name: name, bundleIdentifier: bundleIdentifier, path: fileURL.path, icon: icon)
                apps.append(app)
            }
        }
        
        // Remove duplicates that might appear in both folders and sort alphabetically
        var uniqueApps = Array(Set(apps))
        uniqueApps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        
        return uniqueApps
    }
}
