import 'dart:async';

import 'package:hive/hive.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/blockchain_service.dart';
import '../services/chat_service.dart';
import '../services/evidence_service.dart';
import '../services/infraction_service.dart';
import '../services/report_service.dart';
import '../services/vehicle_type_service.dart';
import '../services/verification_service.dart';
import 'auth_manager.dart';
import 'config.dart';
import 'http_client.dart';
import 'offline_queue.dart';

/// Callback type for SDK lifecycle events.
typedef MultandoEventCallback = void Function(MultandoEvent event);

/// Events emitted by the SDK.
enum MultandoEvent {
  /// Tokens were refreshed automatically.
  tokenRefreshed,

  /// The user was logged out (e.g. refresh token expired).
  sessionExpired,

  /// An offline-queued report was successfully flushed.
  offlineQueueFlushed,

  /// The offline queue failed to flush one or more items.
  offlineQueueFlushFailed,
}

/// Main entry point for the Multando SDK.
///
/// ```dart
/// final client = MultandoClient();
/// await client.initialize(MultandoConfig(
///   baseUrl: 'https://api.multando.io',
///   apiKey: 'your-api-key',
/// ));
/// ```
class MultandoClient {
  MultandoClient();

  late MultandoConfig _config;
  late AuthManager _authManager;
  late MultandoHttpClient _httpClient;
  OfflineQueue? _offlineQueue;
  bool _initialized = false;

  // Services
  late AuthService _authService;
  late ReportService _reportService;
  late EvidenceService _evidenceService;
  late InfractionService _infractionService;
  late VehicleTypeService _vehicleTypeService;
  late VerificationService _verificationService;
  late BlockchainService _blockchainService;
  late ChatService _chatService;

  MultandoEventCallback? _onEvent;
  UserProfile? _currentUser;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Whether the SDK has been initialised.
  bool get isInitialized => _initialized;

  /// Whether the current user is authenticated with a valid access token.
  bool get isAuthenticated => _authManager.isAuthenticated;

  /// The most recently fetched [UserProfile], or `null` if not yet loaded.
  UserProfile? get currentUser => _currentUser;

  /// Number of reports waiting in the offline queue.
  int get offlineQueueCount => _offlineQueue?.count ?? 0;

  /// Stream of authentication state changes (`true` = authenticated).
  Stream<bool> get authStateStream => _authManager.authStateStream;

  /// Register a callback for SDK lifecycle events.
  set onEvent(MultandoEventCallback? callback) => _onEvent = callback;

  // -- Sub-services --

  AuthService get auth {
    _ensureInitialized();
    return _authService;
  }

  ReportService get reports {
    _ensureInitialized();
    return _reportService;
  }

  EvidenceService get evidence {
    _ensureInitialized();
    return _evidenceService;
  }

  InfractionService get infractions {
    _ensureInitialized();
    return _infractionService;
  }

  VehicleTypeService get vehicleTypes {
    _ensureInitialized();
    return _vehicleTypeService;
  }

  VerificationService get verification {
    _ensureInitialized();
    return _verificationService;
  }

  BlockchainService get blockchain {
    _ensureInitialized();
    return _blockchainService;
  }

  ChatService get chat {
    _ensureInitialized();
    return _chatService;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Initialise the SDK with the given [config].
  ///
  /// Must be called before any other method. Initialises secure storage,
  /// the offline queue (if enabled), and loads any persisted auth tokens.
  Future<void> initialize(
    MultandoConfig config, {
    String? hivePath,
  }) async {
    if (_initialized) return;

    _config = config;
    _authManager = AuthManager();

    // Initialise Hive for the offline queue.
    if (hivePath != null) {
      Hive.init(hivePath);
    }

    _httpClient = MultandoHttpClient(
      config: _config,
      authManager: _authManager,
    );

    // Set up offline queue if enabled.
    if (_config.enableOfflineQueue) {
      _offlineQueue = OfflineQueue(httpClient: _httpClient);
      await _offlineQueue!.initialize();
    }

    // Restore persisted tokens.
    await _authManager.loadTokens();

    // Listen for session expiry.
    _authManager.authStateStream.listen((authenticated) {
      if (!authenticated && _currentUser != null) {
        _currentUser = null;
        _onEvent?.call(MultandoEvent.sessionExpired);
      }
    });

    // Wire up services.
    _authService = AuthService(
      httpClient: _httpClient,
      authManager: _authManager,
    );
    _reportService = ReportService(
      httpClient: _httpClient,
      offlineQueue: _offlineQueue,
    );
    _evidenceService = EvidenceService(httpClient: _httpClient);
    _infractionService = InfractionService(httpClient: _httpClient);
    _vehicleTypeService = VehicleTypeService(httpClient: _httpClient);
    _verificationService = VerificationService(httpClient: _httpClient);
    _blockchainService = BlockchainService(httpClient: _httpClient);
    _chatService = ChatService(httpClient: _httpClient);

    _initialized = true;

    // If we already have a token, try to load the user profile.
    if (isAuthenticated) {
      try {
        _currentUser = await _authService.getProfile();
      } catch (_) {
        // Non-fatal; the token may have expired.
      }
    }
  }

  /// Flush the offline queue manually.
  Future<void> flushOfflineQueue() async {
    _ensureInitialized();
    if (_offlineQueue == null) return;
    try {
      await _offlineQueue!.flush();
      _onEvent?.call(MultandoEvent.offlineQueueFlushed);
    } catch (_) {
      _onEvent?.call(MultandoEvent.offlineQueueFlushFailed);
    }
  }

  /// Release all resources held by the SDK.
  Future<void> dispose() async {
    if (!_initialized) return;
    _httpClient.dispose();
    _authManager.dispose();
    await _offlineQueue?.dispose();
    _initialized = false;
    _currentUser = null;
  }

  // ---------------------------------------------------------------------------
  // Internal
  // ---------------------------------------------------------------------------

  void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'MultandoClient has not been initialized. '
        'Call initialize() before using any services.',
      );
    }
  }
}
