import Foundation
import Security

/// Securely stores and retrieves data in the macOS Keychain.
class KeychainManager {
    static let shared = KeychainManager()
    
    private let service = "com.applockpro.faceembeddings"
    private let account = "primaryUserFace"
    
    private init() {}
    
    /// Saves a FaceEmbedding array to the Keychain.
    func saveEmbedding(_ embedding: [Float]) -> Bool {
        do {
            let data = try JSONEncoder().encode(embedding)
            
            // First, delete any existing embedding
            deleteEmbedding()
            
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let status = SecItemAdd(query as CFDictionary, nil)
            return status == errSecSuccess
        } catch {
            print("Failed to encode embedding for keychain: \(error)")
            return false
        }
    }
    
    /// Retrieves the enrolled FaceEmbedding from the Keychain.
    func getEmbedding() -> [Float]? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject? = nil
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            do {
                let embedding = try JSONDecoder().decode([Float].self, from: data)
                return embedding
            } catch {
                print("Failed to decode embedding from keychain: \(error)")
            }
        }
        
        return nil
    }
    
    /// Deletes the enrolled embedding from the Keychain.
    @discardableResult
    func deleteEmbedding() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
