package com.didnex.ads
import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors

/** Hosted wallet/push. Bearer token is private app data, scoped to this installation. */
class DidnexAudience(context: Context, serviceOrigin: String) {
    companion object { val sessionId: String = java.util.UUID.randomUUID().toString(); private val registrationLocks=java.util.concurrent.ConcurrentHashMap<String,Any>(); private val registrations=java.util.concurrent.ConcurrentHashMap<String,String>() }
    private val app = context.applicationContext
    private val parsed = Uri.parse(serviceOrigin)
    val origin: String
    private val pool = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private var installation: String? = null
    init {
        require(parsed.scheme == "https" && parsed.host != null && parsed.userInfo == null && parsed.query == null && parsed.fragment == null && (parsed.path.isNullOrEmpty() || parsed.path == "/")) { "service_origin_required" }
        origin = serviceOrigin.trimEnd('/')
    }
    internal fun post(path: String, payload: JSONObject): JSONObject {
        check(Looper.myLooper()!=Looper.getMainLooper()){"use_request_async"}
        val c = URL(origin + path).openConnection() as HttpURLConnection
        c.requestMethod = "POST"; c.instanceFollowRedirects = false; c.connectTimeout = 10000; c.readTimeout = 10000; c.doOutput = true
        c.setRequestProperty("Content-Type", "application/json")
        try {
            c.outputStream.use { it.write(payload.toString().toByteArray(Charsets.UTF_8)) }
            val status = c.responseCode
            val raw = (if (status in 200..299) c.inputStream else c.errorStream)?.use { input -> val output=java.io.ByteArrayOutputStream();val buffer=ByteArray(4096);while(true){val n=input.read(buffer);if(n<0)break;check(output.size()+n<=65536){"response_too_large"};output.write(buffer,0,n)};String(output.toByteArray(),Charsets.UTF_8) } ?: "{}"
            require(raw.length <= 65536) { "response_too_large" }
            val value = JSONObject(raw); check(status in 200..299) { value.optString("code", "http_$status") }; return value
        } finally { c.disconnect() }
    }
    @Synchronized internal fun token(unitId: String): String {
        check(Looper.myLooper()!=Looper.getMainLooper()) {"use_request_async"}
        val scope = origin + ":" + app.packageName
        synchronized(registrationLocks.computeIfAbsent(scope){Any()}) {
        registrations[scope]?.let { installation=it; return it }
        installation?.let { return it }
        val prefs = app.getSharedPreferences("didnex_audience", Context.MODE_PRIVATE)
        val payload = JSONObject().put("action", "register").put("unitId", unitId).put("packageName", app.packageName).put("device", "android")
        prefs.getString(scope, null)?.let { payload.put("installationToken", it) }
        val saved = post("/ad/v1/audience", payload).getString("installationToken")
        require(saved.matches(Regex("^INS_[a-f0-9]{32}\\.[a-f0-9]{64}$"))) { "invalid_installation_response" }
        check(prefs.edit().putString(scope, saved).commit()) { "installation_storage_unavailable" }
        installation = saved; registrations[scope]=saved; return saved
        }
    }
    /** Call on a worker thread, or use requestAsync. No application server is needed. */
    fun call(unitId: String, action: String, data: JSONObject = JSONObject()): JSONObject = post("/ad/v1/audience", data.put("action", action).put("installationToken", token(unitId)))
    fun requestAsync(unitId: String, action: String, data: JSONObject = JSONObject(), callback: (JSONObject?, String?) -> Unit) {
        if(pool.isShutdown){main.post{try{callback(null,"audience_closed")}catch(_:Exception){}};return}
        try { pool.execute { try { val result = call(unitId, action, data); main.post { try { callback(result, null) } catch (_: Exception) {} } } catch (e: Exception) { main.post { try { callback(null,e.message?.takeIf{it.matches(Regex("^[a-zA-Z0-9_.-]{1,100}$"))} ?: "audience_unavailable") } catch (_: Exception) {} } } } }
        catch(_:java.util.concurrent.RejectedExecutionException){main.post{try{callback(null,"audience_closed")}catch(_:Exception){}}}
    }
    /** Optional growth methods never throw to the application callback. */
    fun nextAsync(unitId: String, op: String, data: JSONObject = JSONObject(), callback: (JSONObject?, String?) -> Unit) {
        try { val copy=JSONObject(data.toString());if(!copy.has("sessionId"))copy.put("sessionId",sessionId);copy.put("op",op);requestAsync(unitId,"next",copy,callback) }
        catch(_:Exception){main.post{try{callback(null,"growth_unavailable")}catch(_:Exception){}}}
    }
    fun eventAsync(unitId:String,event:String,externalId:String=java.util.UUID.randomUUID().toString(),callback:(JSONObject?,String?)->Unit={_,_->}) =
        nextAsync(unitId,"sessionEvent",JSONObject().put("event",event).put("externalId",externalId),callback)
    fun reportPush(receipt: String, kind: String, callback: ((Boolean) -> Unit)? = null) {
        if(kind !in listOf("delivered", "received", "displayed", "opened", "dismissed", "action", "failed") || pool.isShutdown){main.post{try{callback?.invoke(false)}catch(_:Exception){}};return}
        try { pool.execute { val ok = try { post("/ad/v1/push-event", JSONObject().put("receipt", receipt).put("kind", kind)); true } catch (_: Exception) { false }; main.post { try{callback?.invoke(ok)}catch(_:Exception){} } } } catch(_:java.util.concurrent.RejectedExecutionException){main.post{try{callback?.invoke(false)}catch(_:Exception){}}}
    }
    fun close() { pool.shutdownNow() }
}
