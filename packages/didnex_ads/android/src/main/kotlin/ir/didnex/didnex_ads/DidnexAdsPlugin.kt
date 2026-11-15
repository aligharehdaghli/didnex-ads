package ir.didnex.didnex_ads

import java.util.concurrent.Executors
import android.content.Context
import android.app.Activity
import android.content.Intent
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.PluginRegistry
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Handler
import android.os.Looper
import com.android.installreferrer.api.InstallReferrerClient
import com.android.installreferrer.api.InstallReferrerStateListener
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/** An operator-supplied licensed engine must bind each request to its actual ad view. */
interface DidnexMeasurementEngine {
    fun start(arguments: Map<*, *>)
    fun event(requestId: String, kind: String)
    fun finish(requestId: String)
}

class DidnexAdsPlugin : FlutterPlugin, MethodChannel.MethodCallHandler,ActivityAware,PluginRegistry.NewIntentListener,PluginRegistry.RequestPermissionsResultListener {
    private var notificationPermissionReply:MethodChannel.Result?=null
    private var activityBinding:ActivityPluginBinding?=null
    private var activity:Activity?=null
    override fun onAttachedToActivity(binding:ActivityPluginBinding){activityBinding=binding;activity=binding.activity;binding.addOnNewIntentListener(this);binding.addRequestPermissionsResultListener(this)}
    override fun onDetachedFromActivity(){activityBinding?.removeOnNewIntentListener(this);activityBinding?.removeRequestPermissionsResultListener(this);notificationPermissionReply?.success(false);notificationPermissionReply=null;activityBinding=null;activity=null}
    override fun onDetachedFromActivityForConfigChanges(){onDetachedFromActivity()}
    override fun onReattachedToActivityForConfigChanges(binding:ActivityPluginBinding){onAttachedToActivity(binding)}
    override fun onNewIntent(intent:Intent):Boolean{activity?.intent=intent;channel?.invokeMethod("didnexPushOpened",null);return false}
    override fun onRequestPermissionsResult(code:Int,permissions:Array<out String>,grants:IntArray):Boolean{if(code!=9421)return false;notificationPermissionReply?.success(context?.let{com.didnex.ads.DidnexNotifications.permitted(it)}?:false);notificationPermissionReply=null;return true}
    companion object { @JvmStatic var measurementEngine: DidnexMeasurementEngine? = null }
    private var context: Context? = null
    private var integrityPool=Executors.newSingleThreadExecutor()
    private val integrityProviders=mutableMapOf<String,Any>()
    private var channel: MethodChannel? = null
    private val referrers = mutableSetOf<InstallReferrerClient>()
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        if(integrityPool.isShutdown) integrityPool=Executors.newSingleThreadExecutor()
        channel = MethodChannel(binding.binaryMessenger, "ir.didnex.ads/native").also { it.setMethodCallHandler(this) }
    }
    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel?.setMethodCallHandler(null); channel = null; context = null
        integrityPool.shutdownNow();integrityProviders.clear()
        synchronized(referrers) { referrers.forEach { try{it.endConnection()}catch(_:Exception){} }; referrers.clear() }
    }
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if(call.method.startsWith("push")){
            val app=context?:run{result.error("plugin_detached",null,null);return}
            try{when(call.method){
                "pushRequestPermission"->{val a=activity;if(a==null||notificationPermissionReply!=null){result.success(false)}else if(android.os.Build.VERSION.SDK_INT<33){result.success(com.didnex.ads.DidnexNotifications.permitted(app))}else{notificationPermissionReply=result;com.didnex.ads.DidnexNotifications.requestPermission(a,9421)}}
                "pushTransport"->result.success(app.getSharedPreferences("didnex_push",0).getString("transport","fcm"))
                "pushDirectConfigure"->result.success(com.didnex.ads.DidnexDirectPush.configure(app,call.argument<String>("origin")?:"",call.argument<String>("token")?:"",call.argument<Number>("expiresAt")?.toLong()?:0L,call.argument<Boolean>("background")==true))
                "pushDirectRestore"->{com.didnex.ads.DidnexDirectPush.restore(app);com.didnex.ads.DidnexDirectPush.retryPendingOptOut(app);result.success(com.didnex.ads.DidnexDirectPush.state(app))}
                "pushDirectStop"->{com.didnex.ads.DidnexDirectPush.stop(app,call.argument<Boolean>("revoke")==true);result.success(true)}
                "pushConsent"->result.success(com.didnex.ads.DidnexNotifications.consented(app))
                "pushPermission"->result.success(com.didnex.ads.DidnexNotifications.permitted(app))
                "pushTakeOpened"->result.success(com.didnex.ads.DidnexNotifications.takeIntent(app,activity?.intent))
                "pushConfigure"->{if(call.argument<Boolean>("consent")==true)com.didnex.ads.DidnexDirectPush.stop(app,false);app.getSharedPreferences("didnex_push",0).edit().putString("transport",call.argument<String>("transport")?:"fcm").apply();com.didnex.ads.DidnexNotifications.configure(app,call.argument<String>("origin")?:"",call.argument<Boolean>("consent")==true);result.success(true)}
                "pushPresent"->result.success(com.didnex.ads.DidnexNotifications.display(app,call.argument<String>("json")?:"{}"))
                else->result.notImplemented()
            }}catch(_:Exception){result.error("notification_unavailable",null,null)};return
        }
        if(call.method=="appInfo"){val app=context;if(app==null)result.error("plugin_detached",null,null)else result.success(app.packageName);return}
        if(call.method=="audienceRead" || call.method=="audienceWrite"){
            val app=context?:run{result.error("plugin_detached",null,null);return}
            val scope=call.argument<String>("scope")?:run{result.error("scope_required",null,null);return}
            val token=call.argument<String>("token")
            try{integrityPool.execute{try{val prefs=app.getSharedPreferences("didnex_audience",Context.MODE_PRIVATE);val value=if(call.method=="audienceRead")prefs.getString(scope,null)else{check(token!=null);check(prefs.edit().putString(scope,token).commit());null};Handler(Looper.getMainLooper()).post{if(channel!=null)result.success(value)}}catch(_:Exception){Handler(Looper.getMainLooper()).post{if(channel!=null)result.error("storage_unavailable",null,null)}}}}catch(_:Exception){result.error("plugin_detached",null,null)}
            return
        }

        if(call.method=="integrityProof"){
            val app=context?:run{result.error("plugin_detached",null,null);return};val origin=call.argument<String>("serviceOrigin");val unit=call.argument<String>("unitId");val nonce=call.argument<String>("requestNonce")
            if(origin==null||unit==null||nonce==null){result.error("integrity_configuration_required",null,null);return}
            try{integrityPool.execute{try{val provider=integrityProviders.getOrPut(origin){Class.forName("com.didnex.ads.DidnexIntegrity").getConstructor(Context::class.java,String::class.java).newInstance(app,origin)};val proof=provider.javaClass.getMethod("proof",String::class.java,String::class.java,String::class.java).invoke(provider,unit,nonce,call.argument<String>("installationToken")) as org.json.JSONObject;val map=proof.keys().asSequence().associateWith{proof.get(it)};Handler(Looper.getMainLooper()).post{result.success(map)}}catch(_:Exception){Handler(Looper.getMainLooper()).post{result.error("integrity_unavailable",null,null)}}}}catch(_:Exception){result.error("plugin_detached",null,null)};return
        }
        if (call.method == "installReferrer") { try { readReferrer(result) } catch (_: Exception) { result.error("install_referrer_unavailable",null,null) }; return }
        val engine = measurementEngine
        if (call.method.startsWith("omid") && engine == null) { result.error("omid_sdk_not_installed", "Register a licensed measurement engine for the actual ad view.", null); return }
        try {
            when (call.method) {
                "networkQuality" -> { val manager=context!!.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager;try{val caps=manager.getNetworkCapabilities(manager.activeNetwork);result.success(if(manager.isActiveNetworkMetered) "low" else if(caps?.hasTransport(NetworkCapabilities.TRANSPORT_WIFI)==true) "high" else "medium")}catch(_:SecurityException){result.success("low")} }
                "audienceRead" -> { val scope = call.argument<String>("scope") ?: error("scope_required"); result.success(context!!.getSharedPreferences("didnex_audience", Context.MODE_PRIVATE).getString(scope, null)) }
                "audienceWrite" -> { val scope = call.argument<String>("scope") ?: error("scope_required"); val token = call.argument<String>("token") ?: error("token_required"); if (!context!!.getSharedPreferences("didnex_audience", Context.MODE_PRIVATE).edit().putString(scope, token).commit()) error("storage_unavailable"); result.success(null) }

                "omidStart" -> { engine!!.start(call.arguments as? Map<*, *> ?: emptyMap<String, Any>()); result.success(null) }
                "omidEvent" -> { engine!!.event(call.argument<String>("requestId") ?: error("request_id_required"), call.argument<String>("kind") ?: error("event_required")); result.success(null) }
                "omidFinish" -> { engine!!.finish(call.argument<String>("requestId") ?: error("request_id_required")); result.success(null) }
                else -> result.notImplemented()
            }
        } catch (_: Exception) { result.error("native_measurement_unavailable", "The native engine did not accept the event.", null) }
    }
    private fun readReferrer(result: MethodChannel.Result) {
        val app = context ?: run { result.error("plugin_detached", null, null); return }
        val client = InstallReferrerClient.newBuilder(app).build()
        val completed = AtomicBoolean(false)
        synchronized(referrers) { referrers.add(client) }
        fun finish(value: Map<String, Any>?, code: String?) {
            if (!completed.compareAndSet(false, true)) return
            client.endConnection(); synchronized(referrers) { referrers.remove(client) }
            if (code == null) result.success(value) else result.error(code, "Install Referrer is unavailable on this installation.", null)
        }
        Handler(Looper.getMainLooper()).postDelayed({ finish(null, "install_referrer_timeout") }, 8000)
        client.startConnection(object : InstallReferrerStateListener {
            override fun onInstallReferrerSetupFinished(responseCode: Int) {
                if (responseCode != InstallReferrerClient.InstallReferrerResponse.OK) { finish(null, "install_referrer_unavailable"); return }
                try {
                    val details = client.installReferrer
                    finish(mapOf("referrer" to details.installReferrer, "clickTimestampSeconds" to details.referrerClickTimestampSeconds, "installTimestampSeconds" to details.installBeginTimestampSeconds), null)
                } catch (_: Exception) { finish(null, "install_referrer_failed") }
            }
            override fun onInstallReferrerServiceDisconnected() { finish(null, "install_referrer_disconnected") }
        })
    }
}
