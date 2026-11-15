import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
/// Local test diagnostics. Never records URLs, headers, tokens or customer data.
class DidnexInspector {
  static bool _diagnostic = false;
  static final ValueNotifier<List<Map<String, Object>>> entries = ValueNotifier([]);
  static void enableDiagnostic() { _diagnostic = true; }
  static void record(String stage, {String? code, String? requestId, int? latencyMs}) {
    if (!kDebugMode && !_diagnostic) return;
    String safe(String v) => RegExp(r'^[a-zA-Z0-9_-]{1,100}$').hasMatch(v) ? v : 'redacted';
    final row = <String,Object>{'at': DateTime.now().millisecondsSinceEpoch,'stage':safe(stage),if(code != null)'code':safe(code),if(requestId != null)'requestId':safe(requestId),if(latencyMs != null)'latencyMs':latencyMs.clamp(0,60000)};
    entries.value = [...entries.value.skip(entries.value.length >= 80 ? 1 : 0),row];
  }
  /// Keep type and frame names locally; never retain raw messages, paths or tokens.
  static void capture(Object error, StackTrace stack, {String stage='exception'}) {
    record(stage,code:error.runtimeType.toString());
    for(final line in stack.toString().split('\n').take(4)) {
      final match=RegExp(r'^#\d+\s+([A-Za-z0-9_.<>]+)').firstMatch(line);
      if(match!=null)record('stack',code:match.group(1)!.replaceAll(RegExp(r'[^A-Za-z0-9_-]'),'_').substring(0,match.group(1)!.length.clamp(0,80).toInt()));
    }
  }
  static String report() => jsonEncode({'sdk':'flutter-3.8.0','entries':entries.value});
  static Future<void> show(BuildContext context) async {
    if (!kDebugMode && !_diagnostic) throw StateError('test_device_required');
    await showModalBottomSheet<void>(context:context,isScrollControlled:true,builder:(context)=>SafeArea(child:SizedBox(height:MediaQuery.sizeOf(context).height*.75,child:Padding(padding:const EdgeInsets.all(20),child:Column(children:[const Text('Didnex SDK Inspector'),const Text('گزارش محلی بدون URL و توکن'),Expanded(child:ValueListenableBuilder<List<Map<String,Object>>>(valueListenable:entries,builder:(_,value,__)=>SingleChildScrollView(child:SelectableText(const JsonEncoder.withIndent('  ').convert(value),textDirection:TextDirection.ltr)))),TextButton(onPressed:()=>Clipboard.setData(ClipboardData(text:report())),child:const Text('کپی گزارش بدون کلید'))])))));
  }
}
