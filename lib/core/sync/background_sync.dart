import 'background_sync_stub.dart'
    if (dart.library.io) 'background_sync_io.dart'
    as latar;

Future<void> registerBackgroundSync() => latar.registerBackgroundSync();
