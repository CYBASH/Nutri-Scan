import 'dart:convert';
import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';
import 'theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageScanHomePage extends StatefulWidget {
  const ImageScanHomePage({super.key});

  @override
  State<ImageScanHomePage> createState() => _ImageScanHomePageState();
}

class _ImageScanHomePageState extends State<ImageScanHomePage> {
  final Gemini gemini = Gemini.instance;

  @override
  void initState() {
    super.initState();
    _loadChatMessages();
  }

  void _loadChatMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? messages = prefs.getStringList('chat_messages');

    if (messages != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      List<ChatMessage> chatMessages = messages.map((msg) => ChatMessage.fromJson(jsonDecode(msg))).toList();
      chatProvider.setMessages(chatMessages);
    }
  }

  // Method to clear chat
  void _clearChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.clearMessages();

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("NutriScan"),
        actions: [
          IconButton(
            // icon: const Icon(Icons.clear),
            icon: const Icon(
              Icons.delete,
              color: Colors.red,  // Set the icon color to red
            ),
            onPressed: _clearChat, // Call clear chat method
          ),
        ],
      ),
      body: DashChat(
        inputOptions: InputOptions(
          trailing: [
            IconButton(
              onPressed: _sendMediaMessage,
              icon: const Icon(Icons.image),
            ),
          ],
          sendButtonBuilder: (Function() onSend) {
            return IconButton(
              icon: Icon(
                Icons.send,
                color: isDarkMode ? Colors.blue[1000] : Colors.blue[500],
              ),
              onPressed: onSend,
            );
          },
          inputTextStyle: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          inputDecoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode ? Colors.grey[800] : Colors.white,
            hintText: "Type a message...",
            hintStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(color: isDarkMode ? Colors.white70 : Colors.black26),
            ),
          ),
        ),
        currentUser: chatProvider.currentUser,
        onSend: _sendMessage,
        messages: chatProvider.messages,
        messageOptions: MessageOptions(
          currentUserContainerColor: isDarkMode ? Colors.green.shade100 : Colors.blue,
          containerColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
          textColor: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage, {Uint8List? imageData}) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(chatMessage);

    try {
      String question = chatMessage.text;

      List<Uint8List>? images;
      if (imageData != null) {
        question = """You are an expert in nutritionist where you need to see the food items from the image
        and calculate the total calories, also provide the details of every food items with calories intake
    is below format.

    1. Item 1 - no of calories
    2. Item 2 - no of calories
    ----
    ----
    Total Calories - sum(no of calories)
    
    Note:
     Take an standard amount of weight like 100 grams of food item.
     Display only guess numbers. no extra explanation is needed.""";
        images = [imageData];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        String response = event.content?.parts?.fold(
            "", (previous, current) => "$previous ${current.text}") ?? "";
        chatProvider.updateLastMessage(response);
      });

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> messages = chatProvider.messages.map((msg) => msg.toJson().toString()).toList();
      await prefs.setStringList('chat_messages', messages);
    } catch (e) {
      print(e);
    }
  }

  void _sendMediaMessage() async {
    ImagePicker picker = ImagePicker();
    XFile? file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      Uint8List imageData = await file.readAsBytes();
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      ChatMessage chatMessage = ChatMessage(
        user: chatProvider.currentUser,
        createdAt: DateTime.now(),
        medias: [
          ChatMedia(
            url: file.path,
            fileName: file.name,
            type: MediaType.image,
          )
        ],
      );

      _sendMessage(chatMessage, imageData: imageData);
    }
  }
}
