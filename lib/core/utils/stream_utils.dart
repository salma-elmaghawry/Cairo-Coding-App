import 'dart:async';

extension SwitchMap<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    late StreamController<R> controller;
    StreamSubscription<T>? outer;
    StreamSubscription<R>? inner;
    var outerDone = false;

    controller = StreamController<R>(
      onListen: () {
        outer = listen(
          (value) {
            inner?.cancel();
            inner = mapper(value).listen(
              controller.add,
              onError: controller.addError,
              onDone: () {
                inner = null;
                if (outerDone) controller.close();
              },
            );
          },
          onError: controller.addError,
          onDone: () {
            outerDone = true;
            if (inner == null) controller.close();
          },
        );
      },
      onPause: () {
        outer?.pause();
        inner?.pause();
      },
      onResume: () {
        outer?.resume();
        inner?.resume();
      },
      onCancel: () async {
        await inner?.cancel();
        await outer?.cancel();
      },
    );
    return controller.stream;
  }
}

Stream<List<T>> combineLatestLists<T>(List<Stream<List<T>>> streams) {
  if (streams.isEmpty) return Stream.value(const []);
  if (streams.length == 1) return streams.single;

  late StreamController<List<T>> controller;
  final latest = List<List<T>?>.filled(streams.length, null);
  final subscriptions = <StreamSubscription<List<T>>>[];

  controller = StreamController<List<T>>(
    onListen: () {
      for (final (index, stream) in streams.indexed) {
        subscriptions.add(
          stream.listen((value) {
            latest[index] = value;
            if (latest.every((list) => list != null)) {
              controller.add([for (final list in latest) ...list!]);
            }
          }, onError: controller.addError),
        );
      }
    },
    onPause: () {
      for (final subscription in subscriptions) {
        subscription.pause();
      }
    },
    onResume: () {
      for (final subscription in subscriptions) {
        subscription.resume();
      }
    },
    onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
  );
  return controller.stream;
}
