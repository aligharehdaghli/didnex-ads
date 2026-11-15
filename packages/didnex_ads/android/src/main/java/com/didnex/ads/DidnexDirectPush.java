package com.didnex.ads;

/** Optional direct OS notifications. No Firebase, foreground service or battery exemption. */
public final class DidnexDirectPush {
 private static final int JOB=0x444e50;
 private static final java.util.concurrent.ScheduledExecutorService IO=java.util.concurrent.Executors.newSingleThreadScheduledExecutor();
 private static final java.util.concurrent.atomic.AtomicBoolean BUSY=new java.util.concurrent.atomic.AtomicBoolean();
 private static java.util.concurrent.ScheduledFuture<?> timer;
 private static android.app.Application application;
 private static boolean lifecycleInstalled;
 private DidnexDirectPush(){}
 private static android.content.SharedPreferences prefs(android.content.Context c){return c.getApplicationContext().getSharedPreferences("didnex_direct_push",0);}
 private static String origin(String raw)throws Exception{java.net.URI u=new java.net.URI(raw);if(!"https".equals(u.getScheme())||u.getHost()==null||u.getRawUserInfo()!=null||u.getQuery()!=null||u.getFragment()!=null||!(u.getPath().isEmpty()||u.getPath().equals("/")))throw new IllegalArgumentException("invalid_origin");return raw.replaceAll("/$","");}
 public static boolean enabled(android.content.Context c){return prefs(c).getBoolean("enabled",false);}
 public static String state(android.content.Context c){try{android.content.SharedPreferences p=prefs(c);return new org.json.JSONObject().put("enabled",enabled(c)).put("transport","direct").put("backgroundScheduled",p.getBoolean("background",false)).put("expiresAt",p.getLong("expires",0)).put("lastPollAt",p.getLong("polled",0)).put("code",p.getString("code","")).toString();}catch(Exception e){return "{}";}}
 /** Call only after explicit consent, OS permission, and a successful server subscription. */
 public static synchronized String configure(android.content.Context context,String serviceOrigin,String token,long expiresAt,boolean background){
  android.content.Context c=context.getApplicationContext();try{
   String base=origin(serviceOrigin);if(!DidnexNotifications.permitted(c)||token==null||token.length()<40||token.length()>4000||expiresAt<=System.currentTimeMillis())throw new IllegalArgumentException("permission_or_token_required");
   prefs(c).edit().putString("origin",base).putString("token",token).putLong("expires",expiresAt).putBoolean("enabled",true).putBoolean("background",false).putString("code","").apply();
   DidnexNotifications.configure(c,base,true);c.getSharedPreferences("didnex_push",0).edit().putString("transport","direct").apply();installLifecycle(c);
   boolean scheduled=false;if(background){try{android.app.job.JobScheduler scheduler=(android.app.job.JobScheduler)c.getSystemService(android.content.Context.JOB_SCHEDULER_SERVICE);android.app.job.JobInfo job=new android.app.job.JobInfo.Builder(JOB,new android.content.ComponentName(c,Job.class)).setRequiredNetworkType(android.app.job.JobInfo.NETWORK_TYPE_ANY).setPeriodic(15*60*1000L).setPersisted(true).build();scheduled=scheduler!=null&&scheduler.schedule(job)==android.app.job.JobScheduler.RESULT_SUCCESS;}catch(Exception ignored){}}
   if(!background)cancelJob(c);prefs(c).edit().putBoolean("background",scheduled).putString("code",background&&!scheduled?"direct_background_manifest_required":"").apply();setActive(c,true);return state(c);
  }catch(Exception e){prefs(c).edit().putString("code","direct_setup_required").apply();return "{\"enabled\":false,\"code\":\"direct_setup_required\"}";}
 }
 public static synchronized void restore(android.content.Context c){if(enabled(c)){installLifecycle(c.getApplicationContext());setActive(c,true);}}
 private static void installLifecycle(android.content.Context c){if(lifecycleInstalled||!(c instanceof android.app.Application))return;application=(android.app.Application)c;lifecycleInstalled=true;application.registerActivityLifecycleCallbacks(new android.app.Application.ActivityLifecycleCallbacks(){
  private int visible;
  public void onActivityResumed(android.app.Activity a){visible++;setActive(application,true);}
  public void onActivityPaused(android.app.Activity a){visible=Math.max(0,visible-1);if(visible==0)setActive(application,false);}
  public void onActivityCreated(android.app.Activity a,android.os.Bundle b){} public void onActivityStarted(android.app.Activity a){} public void onActivityStopped(android.app.Activity a){} public void onActivitySaveInstanceState(android.app.Activity a,android.os.Bundle b){} public void onActivityDestroyed(android.app.Activity a){}
 });}
 public static synchronized void setActive(final android.content.Context context,boolean active){if(timer!=null){timer.cancel(false);timer=null;}if(active&&enabled(context)){final android.content.Context c=context.getApplicationContext();timer=IO.scheduleWithFixedDelay(new Runnable(){public void run(){poll(c);}},0,60,java.util.concurrent.TimeUnit.SECONDS);}}
 private static void cancelJob(android.content.Context c){try{android.app.job.JobScheduler s=(android.app.job.JobScheduler)c.getSystemService(android.content.Context.JOB_SCHEDULER_SERVICE);if(s!=null)s.cancel(JOB);}catch(Exception ignored){}}
 /** Returns local stop immediately. The purpose-scoped server opt-out is retried off the UI thread. */
 public static synchronized void stop(final android.content.Context context,boolean revoke){final android.content.Context c=context.getApplicationContext();final android.content.SharedPreferences p=prefs(c);final String token=p.getString("token",""),base=p.getString("origin","");p.edit().putBoolean("enabled",false).putBoolean("background",false).putBoolean("pendingOptOut",revoke&&!token.isEmpty()).putString("optOutToken",token).putString("optOutOrigin",base).apply();setActive(c,false);cancelJob(c);if(revoke){DidnexNotifications.configure(c,base,false);IO.execute(new Runnable(){public void run(){retryOptOut(c);}});}}
 private static void retryOptOut(android.content.Context c){android.content.SharedPreferences p=prefs(c);if(!p.getBoolean("pendingOptOut",false))return;try{post(p.getString("optOutOrigin",""),"/ad/v1/push-direct",new org.json.JSONObject().put("token",p.getString("optOutToken","")).put("action","unsubscribe"));p.edit().putBoolean("pendingOptOut",false).remove("optOutToken").remove("optOutOrigin").apply();}catch(Exception e){if(e.getMessage()!=null&&(e.getMessage().equals("push_http_403")||e.getMessage().equals("push_http_410")))p.edit().putBoolean("pendingOptOut",false).remove("optOutToken").remove("optOutOrigin").apply();}}
 public static void retryPendingOptOut(final android.content.Context c){IO.execute(new Runnable(){public void run(){retryOptOut(c.getApplicationContext());}});}
 static void reportOpened(String origin,org.json.JSONObject message)throws Exception{
  post(origin,"/ad/v1/push-event",new org.json.JSONObject().put("receipt",message.getString("receipt")).put("kind","opened"));
 }
 private static void receipt(String base,org.json.JSONObject m,String kind)throws Exception{post(base,"/ad/v1/push-event",new org.json.JSONObject().put("receipt",m.getString("receipt")).put("kind",kind).put("code","notification_display_failed"));}
 /** Background jobs and foreground timers share one bounded, non-overlapping request. */
 private static void poll(android.content.Context c){if(!BUSY.compareAndSet(false,true))return;try{
  android.content.SharedPreferences p=prefs(c);if(!enabled(c)){retryOptOut(c);return;}if(p.getLong("expires",0)<=System.currentTimeMillis()){p.edit().putString("code","direct_token_expired").apply();stop(c,false);return;}if(!DidnexNotifications.permitted(c))return;
  String base=p.getString("origin",""),token=p.getString("token","");org.json.JSONObject result=post(base,"/ad/v1/push-direct",new org.json.JSONObject().put("token",token));org.json.JSONArray messages=result.optJSONArray("messages");p.edit().putLong("polled",System.currentTimeMillis()).putString("code","").apply();if(messages==null)return;
  for(int i=0;i<Math.min(messages.length(),5);i++){if(!enabled(c)||!token.equals(p.getString("token","")))break;org.json.JSONObject m=messages.optJSONObject(i);if(m==null||!DidnexNotifications.valid(c,m))continue;try{receipt(base,m,"received");}catch(Exception ignored){}if(!enabled(c))break;boolean displayed=DidnexNotifications.display(c,m.toString());try{receipt(base,m,displayed?"delivered":"failed");}catch(Exception ignored){}}
 }catch(Exception e){prefs(c).edit().putString("code","direct_connection_unavailable").apply();}finally{BUSY.set(false);}}
 private static org.json.JSONObject post(String base,String path,org.json.JSONObject body)throws Exception{
  java.net.HttpURLConnection connection=(java.net.HttpURLConnection)new java.net.URL(origin(base)+path).openConnection();try{connection.setRequestMethod("POST");connection.setInstanceFollowRedirects(false);connection.setConnectTimeout(6000);connection.setReadTimeout(6000);connection.setRequestProperty("Content-Type","application/json");connection.setDoOutput(true);byte[] payload=body.toString().getBytes(java.nio.charset.StandardCharsets.UTF_8);connection.setFixedLengthStreamingMode(payload.length);try(java.io.OutputStream out=connection.getOutputStream()){out.write(payload);}int status=connection.getResponseCode();if(status<200||status>=300)throw new java.io.IOException("push_http_"+status);try(java.io.InputStream in=connection.getInputStream();java.io.ByteArrayOutputStream out=new java.io.ByteArrayOutputStream()){byte[] buffer=new byte[4096];int n;while((n=in.read(buffer))!=-1){if(out.size()+n>131072)throw new java.io.IOException("push_reply_too_large");out.write(buffer,0,n);}return new org.json.JSONObject(new String(out.toByteArray(),java.nio.charset.StandardCharsets.UTF_8));}}finally{connection.disconnect();}
 }
 public static final class Job extends android.app.job.JobService {
  @Override public boolean onStartJob(final android.app.job.JobParameters params){final android.content.Context c=getApplicationContext();IO.execute(new Runnable(){public void run(){try{poll(c);}finally{jobFinished(params,false);}}});return true;}
  @Override public boolean onStopJob(android.app.job.JobParameters params){return enabled(this);}
 }
}
