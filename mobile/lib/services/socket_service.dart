import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import 'storage_service.dart';

/// Socket.IO client service for real-time communication
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  final StorageService _storageService = StorageService();
  
  // Connection state
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Callbacks for events
  final List<Function(dynamic)> _onActivityCreatedCallbacks = [];
  final List<Function(dynamic)> _onParticipantJoinedCallbacks = [];
  final List<Function(dynamic)> _onParticipantLeftCallbacks = [];
  final List<Function(dynamic)> _onNewMessageCallbacks = [];
  final List<Function(dynamic)> _onUserTypingCallbacks = [];
  final List<Function(dynamic)> _onUserOnlineCallbacks = [];
  final List<Function(dynamic)> _onUserOfflineCallbacks = [];

  /// Initialize and connect to socket server
  Future<void> connect() async {
    if (_socket != null && _isConnected) {
      debugPrint('Socket already connected');
      return;
    }

    final token = _storageService.getToken();
    if (token == null) {
      debugPrint('No auth token, cannot connect to socket');
      return;
    }

    try {
      _socket = IO.io(
        ApiConstants.baseUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': token})
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(1000)
            .build(),
      );

      _setupEventListeners();
      
      debugPrint('Socket connecting to ${ApiConstants.baseUrl}...');
    } catch (e) {
      debugPrint('Socket connection error: $e');
    }
  }

  /// Setup socket event listeners
  void _setupEventListeners() {
    if (_socket == null) return;

    // Connection events
    _socket!.onConnect((_) {
      _isConnected = true;
      debugPrint('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((error) {
      _isConnected = false;
      debugPrint('Socket connection error: $error');
    });

    _socket!.onError((error) {
      debugPrint('Socket error: $error');
    });

    // Activity events
    _socket!.on('activity:created', (data) {
      for (var callback in _onActivityCreatedCallbacks) {
        callback(data);
      }
    });

    _socket!.on('activity:participant_joined', (data) {
      for (var callback in _onParticipantJoinedCallbacks) {
        callback(data);
      }
    });

    _socket!.on('activity:participant_left', (data) {
      for (var callback in _onParticipantLeftCallbacks) {
        callback(data);
      }
    });

    _socket!.on('activity:new_message', (data) {
      for (var callback in _onNewMessageCallbacks) {
        callback(data);
      }
    });

    _socket!.on('activity:user_typing', (data) {
      for (var callback in _onUserTypingCallbacks) {
        callback(data);
      }
    });

    // User status events
    _socket!.on('user:online', (data) {
      for (var callback in _onUserOnlineCallbacks) {
        callback(data);
      }
    });

    _socket!.on('user:offline', (data) {
      for (var callback in _onUserOfflineCallbacks) {
        callback(data);
      }
    });
  }

  /// Disconnect from socket server
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
      _isConnected = false;
      debugPrint('Socket disconnected and disposed');
    }
  }

  /// Join an activity room
  void joinActivityRoom(String activityId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('activity:join', activityId);
      debugPrint('Joined activity room: $activityId');
    }
  }

  /// Leave an activity room
  void leaveActivityRoom(String activityId) {
    if (_socket != null && _isConnected) {
      _socket!.emit('activity:leave', activityId);
      debugPrint('Left activity room: $activityId');
    }
  }

  /// Send a message in an activity
  void sendMessage(String activityId, String message) {
    if (_socket != null && _isConnected) {
      _socket!.emit('activity:message', {
        'activityId': activityId,
        'message': message,
      });
    }
  }

  /// Send typing indicator
  void sendTyping(String activityId, bool isTyping) {
    if (_socket != null && _isConnected) {
      _socket!.emit('activity:typing', {
        'activityId': activityId,
        'isTyping': isTyping,
      });
    }
  }

  // ============ Event Listeners ============

  /// Listen for new activity created
  void onActivityCreated(Function(dynamic) callback) {
    _onActivityCreatedCallbacks.add(callback);
  }

  /// Listen for participant joined
  void onParticipantJoined(Function(dynamic) callback) {
    _onParticipantJoinedCallbacks.add(callback);
  }

  /// Listen for participant left
  void onParticipantLeft(Function(dynamic) callback) {
    _onParticipantLeftCallbacks.add(callback);
  }

  /// Listen for new messages
  void onNewMessage(Function(dynamic) callback) {
    _onNewMessageCallbacks.add(callback);
  }

  /// Listen for typing indicator
  void onUserTyping(Function(dynamic) callback) {
    _onUserTypingCallbacks.add(callback);
  }

  /// Listen for user online
  void onUserOnline(Function(dynamic) callback) {
    _onUserOnlineCallbacks.add(callback);
  }

  /// Listen for user offline
  void onUserOffline(Function(dynamic) callback) {
    _onUserOfflineCallbacks.add(callback);
  }

  // ============ Remove Listeners ============

  void removeActivityCreatedListener(Function(dynamic) callback) {
    _onActivityCreatedCallbacks.remove(callback);
  }

  void removeParticipantJoinedListener(Function(dynamic) callback) {
    _onParticipantJoinedCallbacks.remove(callback);
  }

  void removeParticipantLeftListener(Function(dynamic) callback) {
    _onParticipantLeftCallbacks.remove(callback);
  }

  void removeNewMessageListener(Function(dynamic) callback) {
    _onNewMessageCallbacks.remove(callback);
  }

  /// Clear all listeners
  void clearAllListeners() {
    _onActivityCreatedCallbacks.clear();
    _onParticipantJoinedCallbacks.clear();
    _onParticipantLeftCallbacks.clear();
    _onNewMessageCallbacks.clear();
    _onUserTypingCallbacks.clear();
    _onUserOnlineCallbacks.clear();
    _onUserOfflineCallbacks.clear();
  }
}
