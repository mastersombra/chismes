import 'package:chismes/core/services/gossip_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('gossipPublished notifica a todos los listeners', () async {
    final events = GossipEvents();
    var a = 0, b = 0;
    events.onPublished.listen((_) => a++);
    events.onPublished.listen((_) => b++);

    events.gossipPublished();
    await Future<void>.delayed(Duration.zero);

    expect((a, b), (1, 1));
    events.dispose();
  });

  test('dispose cierra el stream', () async {
    final events = GossipEvents();
    final done = expectLater(events.onPublished, emitsDone);
    events.dispose();
    await done;
  });
}
