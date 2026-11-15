import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'models.dart';
class DidnexPresentation {
 DidnexPresentation(this.ad):value=ad.presentation['version']==1?ad.presentation:const {};
 final DidnexAd ad;final Map<String,dynamic> value;
 Color color(String k,int fallback){final s=value[k];return s is String&&RegExp(r'^#[a-fA-F0-9]{6}$').hasMatch(s)?Color(0xff000000|int.parse(s.substring(1),radix:16)):Color(fallback);}
 Color get primary=>color('primaryColor',0xff293970);Color get onPrimary=>color('onPrimaryColor',0xffffffff);Color get surface=>color('surfaceColor',0xffffffff);Color get text=>color('textColor',0xff182338);Color get border=>color('borderColor',0xffe4e8f0);
 double get radius=>value['radiusDp'] is num?(value['radiusDp'] as num).clamp(8,24).toDouble():16;
 bool get left=>value['badgePosition']=='top_left';bool get autoplay=>value['autoPlayVideo']!=false;
 String get name {final n=value['networkName'];return n is String?n.substring(0,n.length>80?80:n.length):'دیدنکس';}
 Uri? asset(Object? value,{bool font=false}){final u=value is String?Uri.tryParse(value):null;if(u==null||u.scheme!='https'||u.origin!=ad.clickUrl.origin||u.userInfo.isNotEmpty||u.hasQuery||u.hasFragment)return null;return u.path.startsWith('/assets/sdk/')||(!font&&RegExp(r'^/brand/BRD_[a-f0-9]{32}$').hasMatch(u.path))?u:null;}
 Uri? get logo=>asset(value['logo'] is Map?value['logo']['url']:null);
 static final Map<String,Future<String?>> _fonts={};
 Future<String?> loadFont(){final f=value['font'];if(f is! Map)return Future.value();final h=f['sha256'],size=f['bytes'],url=asset(f['url'],font:true);if(h is! String||!RegExp(r'^[a-f0-9]{64}$').hasMatch(h)||size is! int||size<1||size>500000||url==null)return Future.value();return _fonts.putIfAbsent(h,()=>_load(url,h,size));}
 static Future<String?> _load(Uri url,String hash,int expected)async{
  final client=HttpClient()..connectionTimeout=const Duration(seconds:4);
  bool valid(Uint8List b)=>b.length==expected&&b.length>4&&((b[0]==0&&b[1]==1&&b[2]==0&&b[3]==0)||(b[0]==79&&b[1]==84&&b[2]==84&&b[3]==79));
  try{final file=File('${Directory.systemTemp.path}/didnex-font-$hash.ttf');Uint8List? bytes;if(await file.exists()){final b=await file.readAsBytes();if(valid(b))bytes=b;}
   if(bytes==null){bytes=await (()async{final q=await client.getUrl(url);q.followRedirects=false;final response=await q.close();if(response.statusCode!=200||response.contentLength>500000)throw const FormatException('font_unavailable');final out=BytesBuilder(copy:false);await for(final b in response){if(out.length+b.length>500000)throw const FormatException('font_too_large');out.add(b);}return out.takeBytes();})().timeout(const Duration(seconds:6));if(!valid(bytes))return null;try{await file.writeAsBytes(bytes,flush:true);}catch(_){}}
   final family='DidnexArabic_${hash.substring(0,16)}';final loader=FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)));await loader.load();return family;
  }catch(_){_fonts.remove(hash);return null;}finally{client.close(force:true);}
 }
}
