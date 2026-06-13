import Foundation
import CryptoKit

public enum Hashing {
    public static func sha256(data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }
    public static func sha256(text: String) -> String {
        sha256(data: Data(text.utf8))
    }
}
