import Foundation
import UserNotifications
import UIKit
@MainActor public enum DidnexNotifications {
 public static func requestPermission() async throws -> Bool {try await UNUserNotificationCenter.current().requestAuthorization(options:[.alert,.badge,.sound])}
 public static func permitted() async -> Bool {let value=await UNUserNotificationCenter.current().notificationSettings();return [.authorized,.provisional,.ephemeral].contains(value.authorizationStatus)&&value.alertSetting == .enabled}
 public static func present(_ message:[String:Any]) async throws -> Bool {
  guard await permitted(),let key=(message["jobId"] ?? message["id"]) as? String,let expiry=Double("\(message["expiresAt"] ?? 0)"),expiry>Date().timeIntervalSince1970*1000 else{return false}
  DidnexNotificationDelegate.shared.install()
  let content=UNMutableNotificationContent();content.title=message["title"] as? String ?? "";content.body=message["body"] as? String ?? "";content.sound = .default;content.userInfo=message
  if let image=message["image"] as? String,let attachment=await imageAttachment(image){content.attachments=[attachment]}
  try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier:"didnex:"+key,content:content,trigger:nil));return true
 }
 private static func imageAttachment(_ raw:String) async -> UNNotificationAttachment? {
  guard let url=URL(string:raw),url.scheme=="https",url.host != nil,url.user==nil,url.password==nil else{return nil}
  do {
   let request=URLRequest(url:url,timeoutInterval:3)
   let (bytes,response)=try await URLSession.shared.bytes(for:request)
   guard let http=response as? HTTPURLResponse,http.statusCode==200,http.url?.scheme=="https",http.url?.host==url.host,http.expectedContentLength<=1_048_576 else{return nil}
   let deadline=Date().addingTimeInterval(4)
   var data=Data()
   for try await byte in bytes {
    guard data.count<1_048_576,Date()<deadline else{return nil}
    data.append(byte)
   }
   let png=data.starts(with:[137,80,78,71,13,10,26,10])
   guard png||data.starts(with:[255,216,255]) else{return nil}
   let file=FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension(png ? "png":"jpg")
   try data.write(to:file)
   defer{try? FileManager.default.removeItem(at:file)}
   return try UNNotificationAttachment(identifier:"didnex-image",url:file)
  } catch{return nil}
 }
 public static func takeOpened()->String{let key="didnex.native.opened",raw=UserDefaults.standard.string(forKey:key) ?? "{}";UserDefaults.standard.removeObject(forKey:key);return raw}
 public static func clear() async {let center=UNUserNotificationCenter.current();let delivered=await center.deliveredNotifications();center.removeDeliveredNotifications(withIdentifiers:delivered.filter{value in if value.request.identifier.hasPrefix("didnex:"){return true};let info=value.request.content.userInfo;return info["receipt"] is String && info["jobId"] is String && URL(string:info["eventUrl"] as? String ?? "")?.path == "/ad/v1/push-event"}.map(\.request.identifier))}
}

private final class DidnexNotificationDelegate:NSObject,UNUserNotificationCenterDelegate {
 static let shared=DidnexNotificationDelegate();weak var previous:UNUserNotificationCenterDelegate?
 func install(){let center=UNUserNotificationCenter.current();if center.delegate !== self{previous=center.delegate;center.delegate=self}}
 func userNotificationCenter(_ center:UNUserNotificationCenter,willPresent notification:UNNotification,withCompletionHandler completionHandler:@escaping(UNNotificationPresentationOptions)->Void){
  if notification.request.identifier.hasPrefix("didnex:"){completionHandler([.banner,.list,.sound])}
  else if let previous,previous.responds(to:#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:))){previous.userNotificationCenter?(center,willPresent:notification,withCompletionHandler:completionHandler)}else{completionHandler([])}
 }
 func userNotificationCenter(_ center:UNUserNotificationCenter,didReceive response:UNNotificationResponse,withCompletionHandler completionHandler:@escaping()->Void){
  if response.notification.request.identifier.hasPrefix("didnex:"),let data=try? JSONSerialization.data(withJSONObject:response.notification.request.content.userInfo),let raw=String(data:data,encoding:.utf8){UserDefaults.standard.set(raw,forKey:"didnex.native.opened")
   let info=response.notification.request.content.userInfo
   if response.actionIdentifier==UNNotificationDefaultActionIdentifier,let expiry=Double("\(info["expiresAt"] ?? 0)"),expiry>Date().timeIntervalSince1970*1000,let rawURL=info["url"] as? String,let url=URL(string:rawURL),["https","http"].contains(url.scheme ?? ""),url.host != nil,url.user==nil,url.password==nil {
    Task{@MainActor in UIApplication.shared.open(url)}
   }
  }
  if let previous,previous.responds(to:#selector(UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:withCompletionHandler:))){previous.userNotificationCenter?(center,didReceive:response,withCompletionHandler:completionHandler)}else{completionHandler()}
 }
}
