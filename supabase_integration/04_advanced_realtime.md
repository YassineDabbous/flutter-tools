# Advanced Real-time Integration

Supabase Real-time is more than just listening to database changes. It includes Broadcast (for ephemeral data) and Presence (for user status). This guide shows how to integrate these into the Caky BLoC architecture.

## 1. Reactive PaginationBloc

To make your lists "live", you can combine `PaginationBloc` with a Supabase stream.

### Implementation Pattern

```dart
mixin SupabaseRealtimeMixin<T extends Identifiable> on PaginationBloc<dynamic, dynamic, T, dynamic> {
  StreamSubscription? _subscription;

  void startRealtime(String table) {
    _subscription = Supabase.instance.client
        .from(table)
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
      // Map raw data to models
      final updatedList = data.map((json) => modelFromMap(json)).toList();
      
      // Update the internal list of the Bloc
      lista = updatedList;
      
      // Emit the update
      emit(bs.pageLoaded(
        data: lista, 
        maxReached: true, // Streams usually return everything in the view
        nextPage: page
      ));
    });
  }

  T modelFromMap(Map<String, dynamic> map);

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
```

## 2. Broadcast for "User Typing" or "Live Updates"

Broadcast allows sending messages between clients without touching the database.

- **Use Case**: Admin seeing live edits from another admin.
- **Integration**: Create a `BroadcastCubit` that manages a `RealtimeChannel`.

```dart
class LiveEditCubit extends Cubit<LiveEditState> {
  late RealtimeChannel channel;

  void join(String room) {
    channel = supabase.channel(room);
    channel.on(
      RealtimeListenTypes.broadcast,
      ChannelFilter(event: 'editing'),
      (payload, [ref]) => emit(payload['user']),
    ).subscribe();
  }

  void notifyEditing(String userName) {
    channel.send(
      type: RealtimeListenTypes.broadcast,
      event: 'editing',
      payload: {'user': userName},
    );
  }
}
```

## 3. Presence for "Who is Online?"

Caky's `concrete` package can use a `PresenceIndicator` widget that listens to a `PresenceCubit`.

- **Benefit**: No changes needed to the `concrete` package; just pass the state from a Supabase-backed Cubit.
- **Pattern**: Use `channel.on(RealtimeListenTypes.presence, ...)` to track joined/left events.
