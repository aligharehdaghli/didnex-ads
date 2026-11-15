/// Own every detached SDK future; never install a global application handler.
void didnexIgnore(Future<dynamic>? pending) {
  pending?.then<void>((_) {}, onError: (Object error, StackTrace stack) {});
}
void didnexCallback(void Function() callback) {
  try { callback(); } catch (_) { /* Host callbacks cannot break ad cleanup. */ }
}
