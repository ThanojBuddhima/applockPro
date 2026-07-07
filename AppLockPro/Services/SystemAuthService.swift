import Foundation
import LocalAuthentication

/// Handles fallback authentication using Touch ID or the Mac login password.
class SystemAuthService {
    static let shared = SystemAuthService()
    
    private init() {}
    
    /// Requests authentication via the system's LocalAuthentication framework.
    /// This natively prompts for Touch ID and provides a fallback to the user's password.
    func authenticate(reason: String, completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, evalError in
                DispatchQueue.main.async {
                    if success {
                        completion(true)
                    } else {
                        if let evalError = evalError {
                            print("System auth failed: \(evalError.localizedDescription)")
                        }
                        completion(false)
                    }
                }
            }
        } else {
            print("System auth not available: \(error?.localizedDescription ?? "Unknown error")")
            DispatchQueue.main.async {
                completion(false)
            }
        }
    }
}
