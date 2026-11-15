package com.didnex.ads
import android.content.Context
import com.google.android.gms.tasks.Tasks
import com.google.android.play.core.integrity.IntegrityManagerFactory
import com.google.android.play.core.integrity.StandardIntegrityManager
import org.json.JSONObject
import java.util.concurrent.TimeUnit
/** Background-thread proof generation. No Google service credentials enter the app. */
class DidnexIntegrity(context:Context,origin:String){
 private val audience=DidnexAudience(context,origin)
 private val manager=IntegrityManagerFactory.createStandard(context.applicationContext)
 private var provider:StandardIntegrityManager.StandardIntegrityTokenProvider?=null
 private var project:Long=0
 @JvmOverloads @Synchronized fun proof(unitId:String,requestNonce:String,installationToken:String?=null):JSONObject{
  val installation=installationToken?:audience.token(unitId)
  val challenge=audience.post("/ad/v1/integrity",JSONObject().put("action","challenge").put("unitId",unitId).put("installationToken",installation).put("requestNonce",requestNonce))
  if(!challenge.optBoolean("enabled"))return JSONObject().put("installationToken",installation)
  val number=challenge.optString("cloudProjectNumber").toLongOrNull()?:error("integrity_project_not_configured")
  if(provider==null||project!=number){provider=Tasks.await(manager.prepareIntegrityToken(StandardIntegrityManager.PrepareIntegrityTokenRequest.builder().setCloudProjectNumber(number).build()),60,TimeUnit.SECONDS);project=number}
  val token=try{Tasks.await(provider!!.request(StandardIntegrityManager.StandardIntegrityTokenRequest.builder().setRequestHash(challenge.getString("requestHash")).build()),15,TimeUnit.SECONDS).token()}catch(e:Exception){provider=null;throw e}
  val result=audience.post("/ad/v1/integrity",JSONObject().put("action","verify").put("unitId",unitId).put("installationToken",installation).put("challengeId",challenge.getString("id")).put("integrityToken",token))
  return JSONObject().put("installationToken",installation).put("requestNonce",requestNonce).put("integrityTicket",result.getString("integrityTicket"))
 }
}
