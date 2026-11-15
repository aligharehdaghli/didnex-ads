import Foundation
import Security
import UIKit
import ImageIO

/// Installation-scoped cloud rewards and consented push. No publisher backend.
@MainActor public final class DidnexAudience {
    public static let sessionID = UUID().uuidString
    public let origin: URL
    private let package: String
    private var savedToken: String?
    private var pending: Task<String, Error>?
    public init(serviceOrigin: URL) throws {
        guard serviceOrigin.scheme == "https", serviceOrigin.host != nil, serviceOrigin.user == nil, serviceOrigin.password == nil, serviceOrigin.query == nil, serviceOrigin.fragment == nil, (serviceOrigin.path.isEmpty || serviceOrigin.path == "/"), let package = Bundle.main.bundleIdentifier else { throw URLError(.badURL) }
        self.origin = serviceOrigin; self.package = package
    }
    private var keychainQuery: [String: Any] { [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:"ir.didnex.audience",kSecAttrAccount as String:origin.absoluteString+":"+package] }
    private func readToken() throws -> String? {
        var query = keychainQuery; query[kSecReturnData as String] = true; query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?; let status = SecItemCopyMatching(query as CFDictionary,&result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { throw NSError(domain:"Didnex.storage",code:Int(status)) }
        return String(data:data,encoding:.utf8)
    }
    private func saveToken(_ token: String) throws {
        let data = Data(token.utf8),query = keychainQuery
        var status = SecItemUpdate(query as CFDictionary,[kSecValueData as String:data] as CFDictionary)
        if status == errSecItemNotFound { var add = query; add[kSecValueData as String] = data; add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly; status = SecItemAdd(add as CFDictionary,nil) }
        guard status == errSecSuccess else { throw NSError(domain:"Didnex.storage",code:Int(status)) }
    }
    func post(_ path: String,_ body: [String: Any]) async throws -> [String: Any] {
        guard let url = URL(string:path,relativeTo:origin)?.absoluteURL else { throw URLError(.badURL) }
        var request = URLRequest(url:url); request.httpMethod="POST"; request.timeoutInterval=10; request.httpShouldHandleCookies=false; request.setValue("application/json",forHTTPHeaderField:"Content-Type"); request.httpBody=try JSONSerialization.data(withJSONObject:body)
        let (data,response)=try await DidnexNetwork.data(for:request)
        guard data.count<=65536,let value=try JSONSerialization.jsonObject(with:data) as? [String:Any] else { throw URLError(.cannotParseResponse) }
        guard let response=response as? HTTPURLResponse,(200..<300).contains(response.statusCode) else { throw NSError(domain:value["code"] as? String ?? "Didnex.http",code:(response as? HTTPURLResponse)?.statusCode ?? 0) }
        return value
    }
    public func installationToken(unitID: String) async throws -> String {
        if let savedToken { return savedToken }; if let pending { return try await pending.value }
        let task=Task<String,Error> { var payload:[String:Any]=["action":"register","unitId":unitID,"packageName":package,"device":"ios"];if let previous=try readToken(){payload["installationToken"]=previous};let result=try await post("/ad/v1/audience",payload);guard let token=result["installationToken"] as? String,token.hasPrefix("INS_") else { throw URLError(.cannotParseResponse) };try saveToken(token);savedToken=token;return token }
        pending=task;defer{pending=nil};return try await task.value
    }
    public func call(unitID: String, action: String, values: [String: Any] = [:]) async throws -> [String: Any] { var payload=values;payload["action"]=action;payload["installationToken"]=try await installationToken(unitID:unitID);return try await post("/ad/v1/audience",payload) }
    /// Optional operations fail closed without throwing to the host app.
    public func next(unitID:String,op:String,values:[String:Any]=[:]) async -> [String:Any] {
        do { var data=values;if data["sessionId"] == nil {data["sessionId"]=Self.sessionID};data["op"]=op;var result=try await call(unitID:unitID,action:"next",values:data);result["ok"]=true;return result }
        catch { return ["ok":false,"code":"growth_unavailable"] }
    }
    /// Report delivered only after display, opened only after the user opens it.
    public func reportPush(receipt: String,kind: String) async throws { guard ["delivered","received","displayed","opened","dismissed","action","failed"].contains(kind) else { throw URLError(.badURL) };_ = try await post("/ad/v1/push-event",["receipt":receipt,"kind":kind]) }
}


/// Shared bounded, cancellable networking; no synchronous Data(contentsOf:).
private final class DidnexNoRedirects:NSObject,URLSessionTaskDelegate,@unchecked Sendable {func urlSession(_ session:URLSession,task:URLSessionTask,willPerformHTTPRedirection response:HTTPURLResponse,newRequest request:URLRequest,completionHandler:@escaping(URLRequest?)->Void){completionHandler(nil)}}
enum DidnexNetwork {
    private struct DecodedImage: @unchecked Sendable { let image: UIImage }
    static func image(_ data: Data) async throws -> UIImage {
        let result=try await Task.detached(priority:.utility) { () throws -> DecodedImage in
            guard let source=CGImageSourceCreateWithData(data as CFData,nil),let props=CGImageSourceCopyPropertiesAtIndex(source,0,nil) as? [CFString:Any],let width=props[kCGImagePropertyPixelWidth] as? Int,let height=props[kCGImagePropertyPixelHeight] as? Int,width>0,height>0,Double(width)*Double(height)<=40000000 else { throw URLError(.cannotDecodeContentData) }
            let options:[CFString:Any]=[kCGImageSourceCreateThumbnailFromImageAlways:true,kCGImageSourceThumbnailMaxPixelSize:2048,kCGImageSourceCreateThumbnailWithTransform:true,kCGImageSourceShouldCacheImmediately:true]
            guard let image=CGImageSourceCreateThumbnailAtIndex(source,0,options as CFDictionary) else { throw URLError(.cannotDecodeContentData) }
            return DecodedImage(image:UIImage(cgImage:image))
        }.value
        return result.image
    }
    static func data(for request: URLRequest, maximum: Int = 65536) async throws -> (Data, URLResponse) {
        let config=URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest=8;config.timeoutIntervalForResource=15
        let session=URLSession(configuration:config,delegate:DidnexNoRedirects(),delegateQueue:nil)
        defer { session.invalidateAndCancel() }
        let (bytes,response)=try await session.bytes(for:request)
        if response.expectedContentLength>Int64(maximum) { throw URLError(.dataLengthExceedsMaximum) }
        var data=Data();data.reserveCapacity(min(maximum,65536))
        for try await byte in bytes { try Task.checkCancellation();if data.count>=maximum { throw URLError(.dataLengthExceedsMaximum) };data.append(byte) }
        return (data,response)
    }
    static func data(from url: URL, maximum: Int = 20*1024*1024) async throws -> (Data, URLResponse) {
        try await data(for:URLRequest(url:url),maximum:maximum)
    }
}
