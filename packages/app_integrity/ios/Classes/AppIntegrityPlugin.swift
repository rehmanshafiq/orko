import CryptoKit
import DeviceCheck
import Flutter
import Foundation
import Security

/// `orko/app_integrity` channel (iOS side): Apple App Attest.
///
/// The key id and "attested" flag live in the Keychain (this-device-only, so
/// they never follow a backup to another phone, where the Secure Enclave key
/// would not exist). State is process-wide and only touched on the main
/// thread, so every engine (phone, CarPlay) sees and serialises on the same
/// key.
public final class AppIntegrityPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "orko/app_integrity", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(AppIntegrityPlugin(), channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        AttestStore.resetIfReinstalled()
        let args = call.arguments as? [String: Any] ?? [:]
        let service = DCAppAttestService.shared

        switch call.method {
        case "state":
            result([
                "supported": service.isSupported,
                "keyId": AttestStore.keyId as Any,
                "attested": AttestStore.attested,
            ])

        case "generateKey":
            guard service.isSupported else { return result(Self.unsupported) }
            KeyGenerator.generate(replacing: args["replacing"] as? String) { outcome in
                switch outcome {
                case .success(let keyId): result(keyId)
                case .failure(let error): result(Self.flutterError(error))
                }
            }

        case "attestKey":
            guard service.isSupported else { return result(Self.unsupported) }
            guard let keyId = args["keyId"] as? String, let challenge = args["challenge"] as? String else {
                return result(Self.invalidInput)
            }
            service.attestKey(keyId, clientDataHash: Self.sha256(challenge)) { attestation, error in
                DispatchQueue.main.async {
                    if let attestation = attestation {
                        result(attestation.base64EncodedString())
                    } else {
                        result(Self.flutterError(error))
                    }
                }
            }

        case "markAttested":
            if let keyId = args["keyId"] as? String, keyId == AttestStore.keyId {
                AttestStore.attested = true
            }
            result(nil)

        case "reset":
            // Only clear the key the caller saw fail, so a stale reset can't
            // wipe a key another engine has just attested.
            if let keyId = args["keyId"] as? String, keyId != AttestStore.keyId {
                return result(nil)
            }
            AttestStore.clear()
            result(nil)

        case "generateAssertion":
            guard service.isSupported else { return result(Self.unsupported) }
            guard let keyId = args["keyId"] as? String, let clientData = args["clientData"] as? String else {
                return result(Self.invalidInput)
            }
            service.generateAssertion(keyId, clientDataHash: Self.sha256(clientData)) { assertion, error in
                DispatchQueue.main.async {
                    if let assertion = assertion {
                        // Standard (not URL-safe) base64, as the backend expects.
                        result(assertion.base64EncodedString())
                    } else {
                        result(Self.flutterError(error))
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private static func sha256(_ text: String) -> Data {
        Data(SHA256.hash(data: Data(text.utf8)))
    }

    private static let unsupported = FlutterError(code: "unsupported", message: nil, details: nil)
    private static let invalidInput = FlutterError(code: "invalid_input", message: nil, details: nil)

    fileprivate static func flutterError(_ error: Error?) -> FlutterError {
        let code: String
        switch (error as? DCError)?.code {
        case .featureUnsupported?: code = "unsupported"
        case .invalidKey?: code = "invalid_key"
        case .invalidInput?: code = "invalid_input"
        case .serverUnavailable?: code = "server_unavailable"
        default: code = "unknown"
        }
        return FlutterError(code: code, message: error?.localizedDescription, details: nil)
    }
}

/// Single-flight, compare-and-swap key generation (main thread only).
private enum KeyGenerator {
    private static var waiters: [(Result<String, Error>) -> Void]?

    static func generate(replacing: String?, completion: @escaping (Result<String, Error>) -> Void) {
        // Someone already has (or just rotated to) a different key: share it.
        if let stored = AttestStore.keyId, stored != replacing {
            return completion(.success(stored))
        }
        if waiters != nil {
            waiters?.append(completion)
            return
        }
        waiters = [completion]
        DCAppAttestService.shared.generateKey { keyId, error in
            DispatchQueue.main.async {
                let outcome: Result<String, Error>
                if let keyId = keyId {
                    AttestStore.keyId = keyId
                    AttestStore.attested = false
                    outcome = .success(keyId)
                } else {
                    outcome = .failure(error ?? DCError(.unknownSystemFailure))
                }
                let pending = waiters ?? []
                waiters = nil
                pending.forEach { $0(outcome) }
            }
        }
    }
}

/// Keychain-backed App Attest state.
private enum AttestStore {
    private static let service = "com.orkohubco.appattest"
    private static let keyIdAccount = "keyId"
    private static let attestedAccount = "attested"
    private static let installMarker = "app_integrity.installed"
    private static var checkedInstall = false

    static var keyId: String? {
        get { read(keyIdAccount) }
        set { write(keyIdAccount, newValue) }
    }

    static var attested: Bool {
        get { read(attestedAccount) == "1" }
        set { write(attestedAccount, newValue ? "1" : nil) }
    }

    static func clear() {
        keyId = nil
        attested = false
    }

    /// Keychain items outlive an uninstall but the Secure Enclave key does not,
    /// and UserDefaults is wiped. A missing marker means a fresh install: drop
    /// any stale key id so we attest a new key instead of signing with a dead one.
    static func resetIfReinstalled() {
        guard !checkedInstall else { return }
        checkedInstall = true
        let defaults = UserDefaults.standard
        if !defaults.bool(forKey: installMarker) {
            clear()
            defaults.set(true, forKey: installMarker)
        }
    }

    private static func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }

    private static func read(_ account: String) -> String? {
        var query = baseQuery(account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func write(_ account: String, _ value: String?) {
        let query = baseQuery(account)
        SecItemDelete(query as CFDictionary)
        guard let value = value else { return }
        var attributes = query
        attributes[kSecValueData as String] = Data(value.utf8)
        // Readable in the background (CarPlay, live-charging refresh) once the
        // device has been unlocked; never migrated to another device.
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(attributes as CFDictionary, nil)
    }
}
