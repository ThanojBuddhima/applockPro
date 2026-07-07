import Foundation
import AppKit

let bundleId = "net.whatsapp.WhatsApp" // Or whatever it is

let apps = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
print("URL: \(String(describing: apps))")
