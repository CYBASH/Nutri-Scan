import 'dart:typed_data';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'chat_provider.dart';

class ImageScanHomePage extends StatefulWidget {
  const ImageScanHomePage({super.key});

  @override
  State<ImageScanHomePage> createState() => _ImageScanHomePageState();
}

class _ImageScanHomePageState extends State<ImageScanHomePage> {
  final Gemini gemini = Gemini.instance;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Gemini Chat"),
      ),
      body: DashChat(
        inputOptions: InputOptions(trailing: [
          IconButton(
              onPressed: _sendMediaMessage, icon: const Icon(Icons.image))
        ]),
        currentUser: chatProvider.currentUser,
        onSend: _sendMessage,
        messages: chatProvider.messages,
      ),
    );
  }

  void _sendMessage(ChatMessage chatMessage, {Uint8List? imageData}) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.addMessage(chatMessage);

    try {
      String question =
          "make sure to give reply in plain text don't use bold or italic text. " +
              chatMessage.text;
      List<Uint8List>? images;
      if (imageData != null) {
        images = [imageData];
      }
      gemini.streamGenerateContent(question, images: images).listen((event) {
        String response = event.content?.parts?.fold(
            "", (previous, current) => "$previous ${current.text}") ??
            "";
        chatProvider.updateLastMessage(response);
      });
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
        text: "Identify the thing in the picture.",
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
