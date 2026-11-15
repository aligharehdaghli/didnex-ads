import 'package:flutter/material.dart';
import 'package:didnex_ads/didnex_ads.dart';

void main() => runApp(const MaterialApp(home: DidnexExample()));

class DidnexExample extends StatefulWidget {
  const DidnexExample({super.key});
  @override
  State<DidnexExample> createState() => _DidnexExampleState();
}

class _DidnexExampleState extends State<DidnexExample> {
  final _form = GlobalKey<FormState>();
  final _proxy = TextEditingController();
  final _package = TextEditingController();
  bool _direct = true;
  final _unit = TextEditingController();
  final _session = TextEditingController();
  final _test = TextEditingController();
  DidnexAdClient? _client;
  int _generation = 0;
  bool _busy = false, _inline = false;
  DidnexAdFormat _format = DidnexAdFormat.banner;
  String _activeUnit = "";
  String? _activeTest;
  String _message = 'برای اتصال مستقیم، نشانی خود دیدنکس، شناسه بسته و جایگاه را وارد کنید؛ سرور و ورود نیاز نیست.';
  Future<void> _show() async {
    if (_busy || !_form.currentState!.validate()) return;
    final old = _client, jwt = _session.text.trim(), format = _format;
    final next = _direct
        ? DidnexAdClient.direct(adOrigin: Uri.parse(_proxy.text.trim()), packageName: _package.text.trim())
        : DidnexAdClient(proxyUrl: Uri.parse(_proxy.text.trim()), sessionToken: () async => jwt);
    final unit = _unit.text.trim(),
        diagnostic = _test.text.trim().isEmpty ? null : _test.text.trim();
    setState(() {
      _client = next;
      _busy = true;
      _inline = !format.isFullscreen;
      _activeUnit = unit;
      _activeTest = diagnostic;
      ++_generation;
      _message = 'در حال درخواست تبلیغ…';
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => old?.close());
    try {
      if (format.isFullscreen) {
        final loaded = await DidnexFullscreenAd.load(
            client: next,
            unitId: unit,
            rewarded: format.isRewarded,
            diagnosticToken: diagnostic);
        if (!mounted) return;
        if (loaded == null) {
          setState(() => _message = 'تبلیغ واجد شرایط وجود ندارد.');
          return;
        }
        await loaded.show(context, onReward: (receipt) {
          if (mounted)
            setState(() => _message =
                'جایزه ثبت شد: ${receipt.reward.amount} ${receipt.reward.label} · ${receipt.grantId}');
        });
      }
    } catch (e) {
      if (mounted) setState(() => _message = 'اتصال ناموفق: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          appBar: AppBar(title: const Text('اتصال تبلیغات دیدنکس')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'حالت مستقیم سرور، ورود و JWT لازم ندارد. هر ۹ فرمت بدون سرور قابل اتصال است؛ جایزه مستقیم در کیف نصب دیدنکس ثبت می‌شود. کلید md_ هرگز وارد اپ نمی‌شود.',
                ),
                const SizedBox(height: 16),
                Form(
                  key: _form,
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('اتصال مستقیم بدون سرور'),
                        value: _direct,
                        onChanged: _busy ? null : (value) => setState(() { _direct = value; _format = DidnexAdFormat.banner; }),
                      ),
                      TextFormField(
                        controller: _proxy,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: _direct ? 'نشانی خود دیدنکس (HTTPS)' : 'نشانی پراکسی نصب‌شده روی سرور خود اپ',
                        ),
                        validator: (text) {
                          final u = Uri.tryParse(text ?? '');
                          return u?.scheme == 'https' && u!.host.isNotEmpty
                              ? null
                              : 'نشانی HTTPS معتبر لازم است.';
                        },
                      ),
                      TextFormField(
                        controller: _unit,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(labelText: 'unitId'),
                        validator: (text) => (text ?? '').trim().length >= 5
                            ? null
                            : 'شناسه جایگاه لازم است.',
                      ),
                      if (_direct) TextFormField(
                        controller: _package,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(labelText: 'شناسه بسته ثبت‌شده؛ مثل com.company.app'),
                        validator: (text) => RegExp(r'^[A-Za-z][A-Za-z0-9_]*(\.[A-Za-z][A-Za-z0-9_]*)+$').hasMatch(text ?? '') ? null : 'شناسه بسته معتبر لازم است.',
                      ),
                      if (!_direct) TextFormField(
                        controller: _session,
                        textDirection: TextDirection.ltr,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: const InputDecoration(
                          labelText: 'App session JWT (not a Didnex API key)',
                        ),
                        validator: (text) => (text ?? '').isEmpty ||
                                (text ?? '').startsWith('md_')
                            ? 'توکن نشست اپ را وارد کنید.'
                            : null,
                      ),
                      TextFormField(
                        controller: _test,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(
                          labelText:
                              'diagnosticToken (optional, from publisher panel)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButton<DidnexAdFormat>(
                        value: _format,
                        isExpanded: true,
                        items: DidnexAdFormat.values
                            .map((f) => DropdownMenuItem(
                                value: f, child: Text(f.wireName)))
                            .toList(),
                        onChanged: _busy
                            ? null
                            : (value) {
                                if (value != null)
                                  setState(() => _format = value);
                              },
                      ),
                      FilledButton(
                        onPressed: _busy ? null : _show,
                        child: const Text('درخواست یک تبلیغ'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(_message),
                const SizedBox(height: 16),
                if (_client != null && _inline)
                  DidnexAdView(
                    key: ValueKey(_generation),
                    unitId: _activeUnit,
                    client: _client,
                    diagnosticToken: _activeTest,
                    autoPlayVideo: false,
                    loadingBuilder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                    noFillBuilder: (_, reason) =>
                        Text('تبلیغی موجود نیست: $reason'),
                    errorBuilder: (_, code) =>
                        Text('اتصال یا نمایش ناموفق بود: $code'),
                    onEvent: (event) {
                      if (!mounted) return;
                      setState(
                        () => _message =
                            '${event.type.name} · ${event.code ?? event.requestId ?? ''}',
                      );
                    },
                  ),
                const SizedBox(height: 24),
                const Text(
                  'این مثال اطلاعات نشست را ذخیره نمی‌کند. جایگاه و کمپین باید در پنل تأیید شده باشند. برای اتصال از اپ، دامنه دیدنکس باید عمومی و قابل دسترسی باشد.',
                ),
              ],
            ),
          ),
        ),
      );
  @override
  void dispose() {
    _client?.close();
    _proxy.dispose();
    _package.dispose();
    _unit.dispose();
    _session.dispose();
    _test.dispose();
    super.dispose();
  }
}
