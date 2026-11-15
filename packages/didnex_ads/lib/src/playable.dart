import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Six bounded native games. Scores are local and never grant a financial reward.
class DidnexPlayable extends StatefulWidget {
  const DidnexPlayable({super.key, required this.config, required this.onReady});
  final Map<String, dynamic> config;
  final VoidCallback onReady;
  @override
  State<DidnexPlayable> createState() => _DidnexPlayableState();
}

class _DidnexPlayableState extends State<DidnexPlayable> {
  static const templates = {'tap_target', 'memory_pairs', 'color_match', 'quick_math', 'number_order', 'sequence_memory'};
  static const names = ['آبی', 'سبز', 'نارنجی', 'بنفش'];
  static const palette = [Color(0xff60a5fa), Color(0xff4ade80), Color(0xfffb923c), Color(0xffc4b5fd)];
  final random = Random();
  final clock = Stopwatch();
  final pending = <Timer>{};
  Timer? timer;
  int score = 0, seconds = 20, target = 5, expected = 1, answer = 0, sequenceIndex = 0;
  bool done = false, locked = false, started = false, won = false;
  double x = .5, y = .5;
  int? first;
  String prompt = '', feedback = '';
  List<int> cards = [], options = [], sequence = [];
  final matched = <int>{}, revealed = <int>{};
  String get game => widget.config['template'] as String;
  int get duration => (widget.config['durationSeconds'] as num? ?? 20).toInt().clamp(5, 30).toInt();

  @override
  void initState() {
    super.initState();
    if (!templates.contains(widget.config['template'])) throw ArgumentError('unsupported_playable_template');
    seconds = duration;
    target = (widget.config['target'] as num? ?? 5).toInt().clamp(2, 20).toInt();
    WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted) widget.onReady(); });
  }

  void later(int ms, VoidCallback action) {
    late Timer task;
    task = Timer(Duration(milliseconds: ms), () {
      pending.remove(task);
      if (mounted && !done) setState(action);
    });
    pending.add(task);
  }

  void finish(bool complete) {
    done = true; won = complete; timer?.cancel(); clock.stop();
    for (final task in pending) { task.cancel(); }
    pending.clear(); feedback = '';
  }

  void begin() {
    if (started || done) return;
    setState(() { started = true; clock.start(); round(); });
    timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!mounted || done) return;
      setState(() {
        seconds = max(0, duration - clock.elapsed.inSeconds);
        if (seconds == 0) finish(false);
      });
    });
  }

  void round() {
    feedback = '';
    switch (game) {
      case 'tap_target': prompt = 'ستاره را بگیرید'; break;
      case 'memory_pairs': cards = [0,1,2,3,0,1,2,3]..shuffle(random); prompt = 'چهار جفت همسان پیدا کنید'; break;
      case 'color_match': answer = random.nextInt(4); options = [0,1,2,3]..shuffle(random); prompt = 'رنگ ${names[answer]} را انتخاب کنید'; break;
      case 'quick_math':
        final a = random.nextInt(9) + 1, b = random.nextInt(9) + 1;
        answer = a + b; prompt = '$a + $b = ؟'; final choices = <int>{answer};
        while (choices.length < 4) { choices.add(random.nextInt(20) + 1); }
        options = choices.toList()..shuffle(random); break;
      case 'number_order': expected = 1; options = [1,2,3,4,5,6]..shuffle(random); prompt = 'عدد 1 را لمس کنید'; break;
      case 'sequence_memory':
        sequence = List.generate(min(5, 3 + score ~/ 2), (_) => random.nextInt(4));
        options = [0,1,2,3]; showSequence(); break;
    }
  }

  void showSequence() {
    locked = true; sequenceIndex = 0; revealed.clear(); prompt = 'دنباله را به خاطر بسپارید';
    for (int i = 0; i < sequence.length; i++) {
      final value = sequence[i];
      later(i * 650 + 250, () { revealed.add(value); });
      later(i * 650 + 700, () { revealed.remove(value); });
    }
    later(sequence.length * 650 + 350, () { locked = false; prompt = 'حالا شما تکرار کنید'; });
  }

  bool point() {
    score++; feedback = 'درست بود!';
    if (score >= target) finish(true);
    return !done;
  }

  void tap(int value) {
    if (!started || done || locked) return;
    if (clock.elapsed.inSeconds >= duration) { setState(() { seconds = 0; finish(false); }); return; }
    setState(() {
      switch (game) {
        case 'tap_target': if (point()) { x = random.nextDouble(); y = random.nextDouble(); } break;
        case 'memory_pairs':
          if (matched.contains(value) || first == value) return;
          revealed.add(value);
          if (first == null) { first = value; return; }
          final old = first!; first = null;
          if (cards[old] == cards[value]) {
            matched.addAll([old, value]); score++;
            if (matched.length == 8) finish(true);
          } else {
            locked = true;
            later(650, () { revealed.removeAll([old, value]); locked = false; });
          }
          break;
        case 'color_match':
        case 'quick_math':
          if (value == answer) { if (point()) round(); } else { feedback = 'دوباره تلاش کنید؛ امتیاز کم نمی‌شود.'; }
          break;
        case 'number_order':
          if (value != expected) { feedback = 'عدد $expected را انتخاب کنید.'; return; }
          if (!point()) return;
          expected++;
          if (expected == 7) { round(); } else { prompt = 'عدد $expected را لمس کنید'; }
          break;
        case 'sequence_memory':
          if (value != sequence[sequenceIndex]) { feedback = 'دوباره دنباله را ببینید.'; showSequence(); return; }
          sequenceIndex++;
          if (sequenceIndex == sequence.length && point()) round();
          break;
      }
    });
  }

  Color color(String key, int fallback) {
    final s = widget.config[key];
    return s is String && RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(s) ? Color(int.parse('ff${s.substring(1)}', radix: 16)) : Color(fallback);
  }

  Widget tile(String label, int value, {Color? background, bool disabled = false, bool active = false}) {
    final shade = background ?? color('accent', 0xffa5b4fc);
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: shade, disabledBackgroundColor: shade.withAlpha(140), foregroundColor: shade.computeLuminance() > .179 ? Colors.black : Colors.white, padding: const EdgeInsets.all(4), side: active ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none),
      onPressed: disabled || locked ? null : () => tap(value), child: Text(label, style: const TextStyle(fontSize: 22)),
    );
  }

  Widget board() {
    if (done) return Center(child: Text('${won ? 'عالی بود! هدف کامل شد' : 'زمان بازی تمام شد'} · $score امتیاز', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white)));
    if (!started) return Center(child: FilledButton(onPressed: begin, child: const Text('شروع بازی')));
    if (game == 'tap_target') return LayoutBuilder(builder: (_, box) => Stack(children: [Positioned(left: x * max(0, box.maxWidth - 60), top: y * max(0, box.maxHeight - 60), child: SizedBox(width: 60, height: 60, child: Semantics(label: 'گرفتن ستاره', child: tile('✦', 0))))]));
    final memory = game == 'memory_pairs', order = game == 'number_order';
    final values = memory ? List.generate(8, (i) => i) : options;
    return GridView.count(crossAxisCount: memory ? 4 : order ? 3 : 2, mainAxisSpacing: 6, crossAxisSpacing: 6, childAspectRatio: 1.5, children: values.map((v) {
      final label = memory ? (revealed.contains(v) || matched.contains(v) ? ['◆','★','●','▲'][cards[v]] : '؟') : game == 'color_match' ? names[v] : game == 'sequence_memory' ? '${v + 1}' : '$v';
      return tile(label, v, background: game == 'color_match' || game == 'sequence_memory' ? palette[v] : null, disabled: memory && matched.contains(v) || order && v < expected, active: game == 'sequence_memory' && revealed.contains(v));
    }).toList());
  }

  @override
  Widget build(BuildContext context) => Container(height: 420, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color('background', 0xff141b3d), borderRadius: BorderRadius.circular(12)), child: DecoratedBox(decoration: BoxDecoration(color: const Color(0xe6111827), borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.all(8), child: Column(children: [
    Text(widget.config['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    Text(widget.config['instruction'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white70, fontSize: 12)),
    Text('$score امتیاز · $seconds ثانیه', style: const TextStyle(color: Colors.white)),
    Text(prompt, maxLines: 2, textDirection: game == 'quick_math' ? TextDirection.ltr : TextDirection.rtl, style: const TextStyle(color: Colors.white)),
    Expanded(child: board()),
    Text(feedback, maxLines: 2, style: const TextStyle(color: Colors.white70, fontSize: 12)),
  ]))));

  @override
  void dispose() { timer?.cancel(); clock.stop(); for (final task in pending) { task.cancel(); } pending.clear(); super.dispose(); }
}
