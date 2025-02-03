import 'package:flutter/material.dart';
import 'package:dash_chat_2/dash_chat_2.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatMessage> messages = [];

  ChatUser currentUser = ChatUser(id: "0", firstName: "User");
  ChatUser geminiUser = ChatUser(id: "1", firstName: "Gemini");

  void addMessage(ChatMessage message) {
    messages.insert(0, message);
    notifyListeners();
  }

  void updateLastMessage(String response) {
    if (messages.isNotEmpty && messages.first.user == geminiUser) {
      messages.first.text += response;
      notifyListeners();
    } else {
      messages.insert(
          0,
          ChatMessage(
              user: geminiUser, createdAt: DateTime.now(), text: response));
      notifyListeners();
    }
  }
}
