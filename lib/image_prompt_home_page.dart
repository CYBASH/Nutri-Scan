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
        title: const Text("NutriScan"),
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
      String question = chatMessage.text;

      List<Uint8List>? images;
      if (imageData != null) {

        // String imageQuestion = "I am making an android application to find and calculate the approximate Calories , Protiens , Fats and Carbs in a food item. I will give you an image at input, you need to identify the food item in the image and give me the approximate calories , protiens , fats and carbs of that food item in the image.";
        // gemini.streamGenerateContent(imageQuestion);
        // question = "Now analyse the food item and give me the output i asked before in the format **Calories: 60 kcal , Protein: 0.8g , Fat: 0.2g , Carbs: 15g. per units** . Also the each value should be in new line.";
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
        // text: "Identify the thing in the picture.",
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
