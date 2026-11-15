import Flutter
import UIKit
import Security
import Network
import UserNotifications

public protocol DidnexMeasurementEngine: AnyObject {
    func start(arguments: [String: Any]) throws
    func event(requestId: String, kind: String) throws
    func finish(requestId: String) throws
}
public final class DidnexAdsPlugin: NSObject, FlutterPlugin {
    private var integrityProviders:[String:DidnexIntegrity]=[:]
    private let network = NWPathMonitor()
    override init(){ super.init();network.start(queue: DispatchQueue(label:"ir.didnex.network")) }
    deinit { network.cancel() }
    public static var measurementEngine: DidnexMeasurementEngine?
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "ir.didnex.ads/native", binaryMessenger: registrar.messenger())
        registrar.addMethodCallDelegate(DidnexAdsPlugin(), channel: channel)
    }
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if call.method.hasPrefix("push"){
            let args=call.arguments as? [String:Any] ?? [:]
            Task{@MainActor in do{switch call.method{
            case "pushRequestPermission":result(try await DidnexNotifications.requestPermission())
            case "pushTransport":result(UserDefaults.standard.string(forKey:"didnex.flutter.push.transport") ?? "fcm")
            case "pushTakeOpened":result(DidnexNotifications.takeOpened())
            case "pushConsent":result(UserDefaults.standard.bool(forKey:"didnex.flutter.push.consent"))
            case "pushPermission":result(await DidnexNotifications.permitted())
            case "pushConfigure":UserDefaults.standard.set(args["transport"] as? String ?? "fcm",forKey:"didnex.flutter.push.transport");UserDefaults.standard.set(args["consent"] as? Bool ?? false,forKey:"didnex.flutter.push.consent");if args["consent"] as? Bool != true{await DidnexNotifications.clear()};result(true)
            case "pushPresent":guard UserDefaults.standard.bool(forKey:"didnex.flutter.push.consent"),let raw=args["json"] as? String,let data=raw.data(using:.utf8),let message=try JSONSerialization.jsonObject(with:data) as? [String:Any]else{result(false);return};result(try await DidnexNotifications.present(message))
            default:result(FlutterMethodNotImplemented)
            }}catch{result(FlutterError(code:"notification_unavailable",message:nil,details:nil))}};return
        }
        if call.method=="appInfo" { result(Bundle.main.bundleIdentifier);return }
        if call.method=="integrityProof"{
            guard let args=call.arguments as? [String:Any],let origin=args["serviceOrigin"] as? String,let url=URL(string:origin),let unit=args["unitId"] as? String,let nonce=args["requestNonce"] as? String else{result(FlutterError(code:"integrity_configuration_required",message:nil,details:nil));return}
            Task{@MainActor in do{let provider:DidnexIntegrity;if let saved=integrityProviders[origin]{provider=saved}else{provider=try DidnexIntegrity(serviceOrigin:url);integrityProviders[origin]=provider};result(try await provider.proof(unitID:unit,requestNonce:nonce,installationToken:args["installationToken"] as? String))}catch{result(FlutterError(code:"integrity_unavailable",message:nil,details:nil))}};return
        }
        if call.method == "networkQuality" { let p=network.currentPath;result(p.isExpensive || p.usesInterfaceType(.cellular) ? "low" : p.status == .satisfied && p.usesInterfaceType(.wifi) ? "high" : "medium");return }
        if call.method == "installReferrer" { result(nil); return }
        if call.method == "audienceRead" || call.method == "audienceWrite" {
            guard let args = call.arguments as? [String: Any], let scope = args["scope"] as? String else { result(FlutterError(code:"scope_required",message:nil,details:nil)); return }
            let query: [String: Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"ir.didnex.ads.audience",kSecAttrAccount as String:scope]
            if call.method == "audienceRead" {
                var read = query; read[kSecReturnData as String] = true; read[kSecMatchLimit as String] = kSecMatchLimitOne
                var item: CFTypeRef?; let status = SecItemCopyMatching(read as CFDictionary,&item)
                if status == errSecItemNotFound { result(nil) } else if status == errSecSuccess, let data = item as? Data { result(String(data:data,encoding:.utf8)) } else { result(FlutterError(code:"storage_unavailable",message:nil,details:nil)) }
            } else if let token = args["token"] as? String, let data = token.data(using:.utf8) {
                let status = SecItemUpdate(query as CFDictionary,[kSecValueData as String:data] as CFDictionary)
                if status == errSecItemNotFound { var add = query; add[kSecValueData as String] = data; add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly; let inserted = SecItemAdd(add as CFDictionary,nil); result(inserted == errSecSuccess ? nil : FlutterError(code:"storage_unavailable",message:nil,details:nil)) }
                else { result(status == errSecSuccess ? nil : FlutterError(code:"storage_unavailable",message:nil,details:nil)) }
            } else { result(FlutterError(code:"token_required",message:nil,details:nil)) }
            return
        }
        guard call.method.hasPrefix("omid") else { result(FlutterMethodNotImplemented); return }
        guard let engine = Self.measurementEngine else { result(FlutterError(code: "omid_sdk_not_installed", message: "Register a licensed measurement engine for the actual ad view.", details: nil)); return }
        let args = call.arguments as? [String: Any] ?? [:]
        do {
            switch call.method {
            case "omidStart": try engine.start(arguments: args)
            case "omidEvent":
                guard let id = args["requestId"] as? String, let kind = args["kind"] as? String else { throw NSError(domain: "Didnex", code: 1) }
                try engine.event(requestId: id, kind: kind)
            case "omidFinish":
                guard let id = args["requestId"] as? String else { throw NSError(domain: "Didnex", code: 1) }
                try engine.finish(requestId: id)
            default: result(FlutterMethodNotImplemented); return
            }
            result(nil)
        } catch { result(FlutterError(code: "native_measurement_unavailable", message: "The native engine did not accept the event.", details: nil)) }
    }
}
