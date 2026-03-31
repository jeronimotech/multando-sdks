import 'package:flutter/widgets.dart';

import '../core/multando_client.dart';

/// An [InheritedWidget] that provides a [MultandoClient] to its descendants.
///
/// Wrap your widget tree (or a subtree) with [MultandoProvider] so that any
/// child can retrieve the client via [MultandoProvider.of(context)].
///
/// ```dart
/// MultandoProvider(
///   client: myClient,
///   child: MaterialApp(home: MyHomePage()),
/// );
/// ```
class MultandoProvider extends InheritedWidget {
  const MultandoProvider({
    super.key,
    required this.client,
    required super.child,
  });

  /// The [MultandoClient] instance shared with the widget tree.
  final MultandoClient client;

  /// Retrieve the nearest [MultandoClient] from the widget tree.
  ///
  /// Throws a [FlutterError] if no [MultandoProvider] is found above
  /// [context].
  static MultandoClient of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MultandoProvider>();
    if (provider == null) {
      throw FlutterError(
        'MultandoProvider.of() called with a context that does not contain '
        'a MultandoProvider.\n'
        'Wrap your widget tree with MultandoProvider before using this method.',
      );
    }
    return provider.client;
  }

  /// Optionally retrieve the nearest [MultandoClient], returning `null` if
  /// no [MultandoProvider] exists above [context].
  static MultandoClient? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<MultandoProvider>();
    return provider?.client;
  }

  @override
  bool updateShouldNotify(MultandoProvider oldWidget) {
    return client != oldWidget.client;
  }
}
