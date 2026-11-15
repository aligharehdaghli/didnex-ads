package com.didnex.ads;

/** Shared OS presenter. No Firebase dependency or permission prompt at initialization. */
public final class DidnexNotifications {
 private DidnexNotifications(){}
 private static final java.util.concurrent.ExecutorService media = new java.util.concurrent.ThreadPoolExecutor(1,1,0,java.util.concurrent.TimeUnit.SECONDS,new java.util.concurrent.ArrayBlockingQueue<Runnable>(4),new java.util.concurrent.ThreadPoolExecutor.DiscardPolicy());

 /** Only the immutable PendingIntent can start this non-exported activity. */
 public static final class Click extends android.app.Activity {
  @Override protected void onCreate(android.os.Bundle state) {
   super.onCreate(state);
   try {
    org.json.JSONObject payload = new org.json.JSONObject(takeIntent(this,getIntent()));
    if (payload.has("receipt")) {
     android.content.Context app=getApplicationContext();
     String origin=prefs(app).getString("origin","");
     new Thread(new Runnable(){public void run(){try{DidnexDirectPush.reportOpened(origin,payload);}catch(Exception ignored){}}},"didnex-opened").start();
     startActivity(new android.content.Intent(android.content.Intent.ACTION_VIEW,android.net.Uri.parse(payload.getString("url"))).addCategory(android.content.Intent.CATEGORY_BROWSABLE));
    }
   } catch(Exception ignored) {} finally {finish();}
  }
 }

 private static android.graphics.Bitmap downloadImage(String raw) {
  if(raw.isEmpty())return null;
  java.net.HttpURLConnection connection=null;
  try {
   java.net.URI uri=new java.net.URI(raw);
   if(!"https".equalsIgnoreCase(uri.getScheme())||uri.getUserInfo()!=null||uri.getHost()==null||(uri.getPort()!=-1&&uri.getPort()!=443))return null;
   for(java.net.InetAddress address:java.net.InetAddress.getAllByName(uri.getHost()))
    if(address.isAnyLocalAddress()||address.isLoopbackAddress()||address.isLinkLocalAddress()||address.isSiteLocalAddress()||address.isMulticastAddress())return null;
   connection=(java.net.HttpURLConnection)uri.toURL().openConnection();
   connection.setInstanceFollowRedirects(false);
   connection.setConnectTimeout(2500);
   connection.setReadTimeout(2500);
   if(connection.getResponseCode()!=200||connection.getContentLength()>1048576)return null;
   try(java.io.InputStream input=connection.getInputStream();java.io.ByteArrayOutputStream bytes=new java.io.ByteArrayOutputStream()){
    byte[] buffer=new byte[8192];int length;long deadline=android.os.SystemClock.elapsedRealtime()+3500;
    while((length=input.read(buffer))!=-1){
     if(bytes.size()+length>1048576||android.os.SystemClock.elapsedRealtime()>deadline)return null;
     bytes.write(buffer,0,length);
    }
    byte[] image=bytes.toByteArray();
    android.graphics.BitmapFactory.Options options=new android.graphics.BitmapFactory.Options();
    options.inJustDecodeBounds=true;
    android.graphics.BitmapFactory.decodeByteArray(image,0,image.length,options);
    if(options.outWidth<1||options.outHeight<1||options.outWidth>4096||options.outHeight>4096)return null;
    options.inJustDecodeBounds=false;
    options.inSampleSize=Math.max(1,Integer.highestOneBit(Math.max(options.outWidth,options.outHeight)/640));
    return android.graphics.BitmapFactory.decodeByteArray(image,0,image.length,options);
   }
  } catch(Exception ignored){return null;}
  finally{if(connection!=null)connection.disconnect();}
 }

 private static android.content.SharedPreferences prefs(android.content.Context c){return c.getSharedPreferences("didnex_push",0);}
 private static android.app.NotificationManager manager(android.content.Context c){return (android.app.NotificationManager)c.getSystemService(android.content.Context.NOTIFICATION_SERVICE);}
 private static void channel(android.content.Context c){if(android.os.Build.VERSION.SDK_INT>=26&&manager(c)!=null)manager(c).createNotificationChannel(new android.app.NotificationChannel("didnex","اعلان‌های رسانه",android.app.NotificationManager.IMPORTANCE_DEFAULT));}
 public static void configure(android.content.Context c,String origin,boolean consent){prefs(c).edit().putString("origin",origin).putBoolean("consent",consent).apply();channel(c);if(!consent)clear(c);}
 public static boolean consented(android.content.Context c){return prefs(c).getBoolean("consent",false);}
 public static boolean permitted(android.content.Context c){try{channel(c);if(android.os.Build.VERSION.SDK_INT>=33&&c.checkSelfPermission("android.permission.POST_NOTIFICATIONS")!=android.content.pm.PackageManager.PERMISSION_GRANTED)return false;android.app.NotificationManager m=manager(c);return m!=null&&(android.os.Build.VERSION.SDK_INT<24||m.areNotificationsEnabled())&&(android.os.Build.VERSION.SDK_INT<26||m.getNotificationChannel("didnex").getImportance()!=android.app.NotificationManager.IMPORTANCE_NONE);}catch(Exception e){return false;}}
 public static void requestPermission(android.app.Activity a,int code){channel(a);if(android.os.Build.VERSION.SDK_INT>=33)a.requestPermissions(new String[]{"android.permission.POST_NOTIFICATIONS"},code);}
 public static boolean valid(android.content.Context c,org.json.JSONObject m){try{java.net.URI base=new java.net.URI(prefs(c).getString("origin","")),event=new java.net.URI(m.getString("eventUrl")),url=new java.net.URI(m.getString("url"));return consented(c)&&m.optLong("expiresAt",m.optLong("expires_at"))>System.currentTimeMillis()&&!m.optString("receipt").isEmpty()&&!m.optString("jobId",m.optString("id")).isEmpty()&&!m.optString("title").isEmpty()&&!m.optString("body").isEmpty()&&"https".equals(event.getScheme())&&base.getAuthority().equals(event.getAuthority())&&event.getUserInfo()==null&&event.getQuery()==null&&event.getFragment()==null&&"/ad/v1/push-event".equals(event.getPath())&&("https".equals(url.getScheme())||"http".equals(url.getScheme()))&&url.getHost()!=null&&url.getUserInfo()==null;}catch(Exception e){return false;}}
 /** True means a permitted notification was submitted to NotificationManager; it is not proof of viewing. */
 public static synchronized boolean display(android.content.Context c,String raw){try{
  org.json.JSONObject m=new org.json.JSONObject(raw);if(!valid(c,m)||!permitted(c))return false;
  String key=m.optString("jobId",m.optString("id"));m.put("jobId",key).put("expiresAt",m.optLong("expiresAt",m.optLong("expires_at")));android.content.SharedPreferences shown=c.getSharedPreferences("didnex_push_shown",0);if(shown.getLong(key,0)>System.currentTimeMillis())return true;
  android.content.Intent intent=new android.content.Intent(c,Click.class);
  try{c.getPackageManager().getActivityInfo(intent.getComponent(),0);}
  catch(android.content.pm.PackageManager.NameNotFoundException missing){
   intent=c.getPackageManager().getLaunchIntentForPackage(c.getPackageName());
   if(intent==null)return false;
   intent.addFlags(android.content.Intent.FLAG_ACTIVITY_SINGLE_TOP|android.content.Intent.FLAG_ACTIVITY_CLEAR_TOP);
  }
  intent.setData(android.net.Uri.parse("didnex-notification://tap/"+android.net.Uri.encode(key)));
  for(String field:new String[]{"receipt","expiresAt","jobId","eventUrl","url"})intent.putExtra("didnex_"+field,m.optString(field));
  android.app.PendingIntent pending=android.app.PendingIntent.getActivity(c,key.hashCode(),intent,android.app.PendingIntent.FLAG_UPDATE_CURRENT|android.app.PendingIntent.FLAG_IMMUTABLE);
  int icon=c.getResources().getIdentifier("didnex_notification_icon","drawable",c.getPackageName());if(icon==0)icon=android.R.drawable.ic_dialog_info;
  @SuppressWarnings("deprecation") android.app.Notification.Builder b=android.os.Build.VERSION.SDK_INT>=26?new android.app.Notification.Builder(c,"didnex"):new android.app.Notification.Builder(c);
  b.setSmallIcon(icon).setContentTitle(m.getString("title")).setContentText(m.getString("body")).setStyle(new android.app.Notification.BigTextStyle().bigText(m.getString("body"))).setContentIntent(pending).setAutoCancel(true).setOnlyAlertOnce(true).setCategory(android.app.Notification.CATEGORY_MESSAGE);
  if(android.os.Build.VERSION.SDK_INT>=26)b.setTimeoutAfter(Math.max(1,m.optLong("expiresAt")-System.currentTimeMillis()));manager(c).notify("didnex:"+key,key.hashCode(),b.build());
  String image=m.optString("image");
  if(!image.isEmpty()&&android.os.Build.VERSION.SDK_INT>=23){
   android.content.Context app=c.getApplicationContext();
   media.execute(new Runnable(){public void run(){
    android.graphics.Bitmap bitmap=downloadImage(image);
    if(bitmap==null||!valid(app,m)||!permitted(app))return;
    android.app.NotificationManager notifications=manager(app);
    for(android.service.notification.StatusBarNotification active:notifications.getActiveNotifications())
     if(("didnex:"+key).equals(active.getTag())&&active.getId()==key.hashCode()){
      b.setStyle(new android.app.Notification.BigPictureStyle().bigPicture(bitmap).setSummaryText(m.optString("body")));
      notifications.notify(active.getTag(),active.getId(),b.build());break;
     }
   }});
  }
  android.content.SharedPreferences.Editor edit=shown.edit();for(java.util.Map.Entry<String,?> entry:shown.getAll().entrySet())if(!(entry.getValue() instanceof Long)||(Long)entry.getValue()<=System.currentTimeMillis())edit.remove(entry.getKey());if(shown.getAll().size()>500)edit.clear();edit.putLong(key,m.optLong("expiresAt")).apply();return true;
 }catch(Exception e){return false;}}
 public static String takeIntent(android.content.Context c,android.content.Intent intent){if(intent==null)return "{}";try{org.json.JSONObject m=new org.json.JSONObject();for(String key:new String[]{"receipt","expiresAt","jobId","eventUrl","url"}){String value=intent.getStringExtra("didnex_"+key);if(value==null)value=intent.getStringExtra(key);if(value!=null)m.put(key,value);}m.put("expiresAt",m.optLong("expiresAt")).put("title","notification").put("body","notification");if(!valid(c,m))return "{}";for(String key:new String[]{"receipt","expiresAt","jobId","eventUrl","url"}){intent.removeExtra(key);intent.removeExtra("didnex_"+key);}return m.toString();}catch(Exception e){return "{}";}}
 public static void clear(android.content.Context c){try{android.app.NotificationManager m=manager(c);if(m!=null&&android.os.Build.VERSION.SDK_INT>=23)for(android.service.notification.StatusBarNotification n:m.getActiveNotifications())if(n.getTag()!=null&&n.getTag().startsWith("didnex:"))m.cancel(n.getTag(),n.getId());c.getSharedPreferences("didnex_push_shown",0).edit().clear().apply();}catch(Exception ignored){}}
}
