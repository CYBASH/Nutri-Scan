import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';  // For JSON encoding/decoding

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  void addMessage(ChatMessage message) {
    messages.insert(0, message);
    notifyListeners();
    _saveMessages();
  }

  void updateLastMessage(String response) {
    if (messages.isNotEmpty && messages.first.user == geminiUser) {
      messages.first.text += response;
      notifyListeners();
    } else {
      messages.insert(
        0,
        ChatMessage(user: geminiUser, createdAt: DateTime.now(), text: response),
      );
      notifyListeners();
    }
    _saveMessages();
  }

  // Save messages to SharedPreferences
  void _saveMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> messagesJson = messages.map((msg) => jsonEncode(msg.toJson())).toList();
    await prefs.setStringList('chat_messages', messagesJson);
  }

  // Load messages from SharedPreferences
  Future<void> loadMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messagesJson = prefs.getStringList('chat_messages');
    if (messagesJson != null) {
      messages = messagesJson
          .map((jsonStr) => ChatMessage.fromJson(jsonDecode(jsonStr)))
          .toList();
      notifyListeners();
    }
  }

  // Set the initial messages
  void setMessages(List<ChatMessage> newMessages) {
    messages = newMessages;
    notifyListeners();
  }

  // Clear messages and remove them from SharedPreferences
  void clearMessages() async {
    messages.clear();  // Clear the messages list
    notifyListeners();  // Notify listeners to update the UI

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');  // Remove the stored messages from SharedPreferences
  }
}


