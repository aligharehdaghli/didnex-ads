import Foundation
import Security
import CryptoKit
import DeviceCheck
@available(iOS 14.0, *) @MainActor public final class DidnexIntegrity {
 private let audience:DidnexAudience
 private let scope:String
 public init(serviceOrigin:URL)throws{audience=try DidnexAudience(serviceOrigin:serviceOrigin);scope=serviceOrigin.absoluteString+":"+(Bundle.main.bundleIdentifier ?? "")}
 private var query:[String:Any]{[kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"ir.didnex.appattest",kSecAttrAccount as String:scope]}
 private func savedKey()->String?{var q=query;q[kSecReturnData as String]=true;q[kSecMatchLimit as String]=kSecMatchLimitOne;var value:CFTypeRef?;guard SecItemCopyMatching(q as CFDictionary,&value)==errSecSuccess,let data=value as? Data else{return nil};return String(data:data,encoding:.utf8)}
 private func store(_ key:String)throws{let data=Data(key.utf8),status=SecItemUpdate(query as CFDictionary,[kSecValueData as String:data] as CFDictionary);if status==errSecItemNotFound{var q=query;q[kSecValueData as String]=data;q[kSecAttrAccessible as String]=kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly;guard SecItemAdd(q as CFDictionary,nil)==errSecSuccess else{throw URLError(.cannotCreateFile)}}else if status != errSecSuccess{throw URLError(.cannotWriteToFile)}}
 public func proof(unitID:String,requestNonce:String,installationToken:String?=nil)async throws->[String:Any]{
  guard DCAppAttestService.shared.isSupported else{throw NSError(domain:"integrity_unsupported",code:1)}
  let installation:String;if let installationToken{installation=installationToken}else{installation=try await audience.installationToken(unitID:unitID)}
  var payload:[String:Any]=["action":"challenge","unitId":unitID,"installationToken":installation,"requestNonce":requestNonce];if let key=savedKey(){payload["keyId"]=key}
  let challenge=try await audience.post("/ad/v1/integrity",payload);guard challenge["enabled"] as? Bool==true else{return ["installationToken":installation]}
  guard let value=challenge["challenge"] as? String,let cid=challenge["id"] as? String else{throw URLError(.cannotParseResponse)}
  let clientHash=Data(SHA256.hash(data:Data(value.utf8)));var verify:[String:Any]=["action":"verify","unitId":unitID,"installationToken":installation,"challengeId":cid];let key:String
  if challenge["knownKey"] as? Bool==true,let stored=savedKey(){key=stored;verify["assertion"]=try await DCAppAttestService.shared.generateAssertion(key,clientDataHash:clientHash).base64EncodedString()}
  else{key=try await DCAppAttestService.shared.generateKey();verify["attestation"]=try await DCAppAttestService.shared.attestKey(key,clientDataHash:clientHash).base64EncodedString();try store(key)}
  verify["keyId"]=key;let result=try await audience.post("/ad/v1/integrity",verify);guard let ticket=result["integrityTicket"] as? String else{throw URLError(.cannotParseResponse)};return ["installationToken":installation,"requestNonce":requestNonce,"integrityTicket":ticket]
 }
}
