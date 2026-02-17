import 'dart:async';
import 'package:flutter/material.dart';

import '../models/chat_message.dart';

class ChatProvider extends ChangeNotifier {
  final Map<String, List<ChatMessage>> _threads = {};

  List<ChatMessage> messagesFor(String threadId) => List.unmodifiable(_threads[threadId] ?? const []);

  void ensureThread(String threadId, {required String driverName}) {
    _threads.putIfAbsent(threadId, () {
      return [
        ChatMessage(
          id: "m0",
          sender: ChatSender.driver,
          text: "Hi! This is $driverName. I’m on my way.",
          createdAt: DateTime.now(),
        ),
      ];
    });
  }

  void sendUserMessage(String threadId, String text, {required String driverName}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final list = _threads.putIfAbsent(threadId, () => []);
    list.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.user,
      text: trimmed,
      createdAt: DateTime.now(),
    ));
    notifyListeners();

    unawaited(Future.delayed(const Duration(milliseconds: 800), () {
      final replies = [
        "Got it.",
        "On the way.",
        "Okay, thanks!",
        "I’ll be there soon.",
        "Sure.",
      ];
      final reply = replies[DateTime.now().millisecondsSinceEpoch % replies.length];
      final list2 = _threads.putIfAbsent(threadId, () => []);
      list2.add(ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        sender: ChatSender.driver,
        text: reply,
        createdAt: DateTime.now(),
      ));
      notifyListeners();
    }));
  }
}
