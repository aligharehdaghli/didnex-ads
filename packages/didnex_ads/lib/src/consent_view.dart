import 'package:flutter/material.dart';
import 'client.dart';
import 'pro_models.dart';

Future<DidnexConsent?> showDidnexConsent(BuildContext context, {required DidnexAdClient client, required String unitId, String policyVersion = '1', String description = 'تبلیغات زمینه‌ای دیدنکس هویت تبلیغاتی دستگاه را دریافت نمی‌کند. ارسال درخواست به شبکه‌های بیرونی و تحلیل اختیاری را انتخاب کنید.'}) async {
  bool external = false, analytics = false;
  final result = await showDialog<(bool, bool)>(context: context, barrierDismissible: false, builder: (context) => StatefulBuilder(builder: (context, setState) => AlertDialog(
    title: const Text('انتخاب‌های حریم خصوصی'), content: Column(mainAxisSize: MainAxisSize.min, children: [Text(description), CheckboxListTile(value: external, onChanged: (v) => setState(() => external = v ?? false), title: const Text('اجازه اتصال به شبکه‌های تبلیغاتی بیرونی')), CheckboxListTile(value: analytics, onChanged: (v) => setState(() => analytics = v ?? false), title: const Text('اجازه تحلیل اختیاری نمایش'))]), actions: [TextButton(onPressed: () => Navigator.pop(context, (false, false)), child: const Text('فقط تبلیغات زمینه‌ای')), FilledButton(onPressed: () => Navigator.pop(context, (external, analytics)), child: const Text('ذخیره انتخاب‌ها'))],
  )));
  if (result == null) return null;
  return client.updateConsent(unitId, externalAds: result.$1, analytics: result.$2, policyVersion: policyVersion);
}
