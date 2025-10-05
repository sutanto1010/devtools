import 'dart:async';

/// A simple publish-subscribe service for Flutter applications
class PubSubService {
  static final PubSubService _instance = PubSubService._internal();
  factory PubSubService() => _instance;
  PubSubService._internal();

  // Map to store topic subscriptions
  final Map<String, List<StreamController<dynamic>>> _subscriptions = {};

  /// Subscribe to a topic and receive messages
  /// Returns a Stream that will emit messages published to the topic
  Stream<T> subscribe<T>(String topic) {
    final controller = StreamController<T>.broadcast();
    
    if (!_subscriptions.containsKey(topic)) {
      _subscriptions[topic] = [];
    }
    
    _subscriptions[topic]!.add(controller);
    
    // Return the stream and handle cleanup when subscription is cancelled
    return controller.stream.asBroadcastStream()..listen(
      null,
      onDone: () => _removeSubscription(topic, controller),
      cancelOnError: false,
    );
  }

  /// Publish a message to a specific topic
  /// All subscribers to this topic will receive the message
  void publish<T>(String topic, T message) {
    if (_subscriptions.containsKey(topic)) {
      final controllers = List<StreamController<dynamic>>.from(_subscriptions[topic]!);
      
      for (final controller in controllers) {
        if (!controller.isClosed) {
          try {
            controller.add(message);
          } catch (e) {
            // Handle any errors when adding to controller
            print('Error publishing to topic $topic: $e');
          }
        } else {
          // Remove closed controllers
          _subscriptions[topic]!.remove(controller);
        }
      }
      
      // Clean up empty topic lists
      if (_subscriptions[topic]!.isEmpty) {
        _subscriptions.remove(topic);
      }
    }
  }

  /// Unsubscribe from a topic
  void unsubscribe(String topic, StreamController controller) {
    _removeSubscription(topic, controller);
  }

  /// Remove a specific subscription
  void _removeSubscription(String topic, StreamController controller) {
    if (_subscriptions.containsKey(topic)) {
      _subscriptions[topic]!.remove(controller);
      
      if (!controller.isClosed) {
        controller.close();
      }
      
      // Clean up empty topic lists
      if (_subscriptions[topic]!.isEmpty) {
        _subscriptions.remove(topic);
      }
    }
  }

  /// Get all active topics
  List<String> getActiveTopics() {
    return _subscriptions.keys.toList();
  }

  /// Get subscriber count for a topic
  int getSubscriberCount(String topic) {
    return _subscriptions[topic]?.length ?? 0;
  }

  /// Clear all subscriptions for a topic
  void clearTopic(String topic) {
    if (_subscriptions.containsKey(topic)) {
      final controllers = List<StreamController<dynamic>>.from(_subscriptions[topic]!);
      
      for (final controller in controllers) {
        if (!controller.isClosed) {
          controller.close();
        }
      }
      
      _subscriptions.remove(topic);
    }
  }

  /// Clear all subscriptions
  void clearAll() {
    final topics = List<String>.from(_subscriptions.keys);
    for (final topic in topics) {
      clearTopic(topic);
    }
  }

  /// Dispose of the service (cleanup all resources)
  void dispose() {
    clearAll();
  }
}

/// Extension methods for easier usage
extension PubSubExtension on PubSubService {
  /// Convenience method to publish and subscribe in a more fluent way
  void emit(String topic, dynamic message) => publish(topic, message);
  
  Stream<T> on<T>(String topic) => subscribe<T>(topic);
}