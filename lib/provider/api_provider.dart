import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;


import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final aiChatProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final messagesStream = FirebaseFirestore.instance
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();

  return messagesStream.map(
    (snapshot) => snapshot.docs.map((doc) => doc.data()).toList(),
  );
});

final aiServiceProvider = Provider((ref) => AiService());

class AiService {
  final String apiKey =
      "AIzaSyBbsfeUeMq7y_IEc6o5uqNWP6SC-i-ZLJw"; // Gemini API Key

  Future<void> sendMessage(String userMessage) async {
    // 1️⃣ Save user message
    final userData = {
      'text': userMessage,
      'isUser': true,
      'timestamp': DateTime.now(),
    };
    await FirebaseFirestore.instance.collection('messages').add(userData);

    // 2️⃣ Send to Gemini API
    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey",
    );

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text":
                      "You are an AI that always replies in Hinglish (English letters but Hindi tone)."
                      "Users $userMessage",
                },
              ],
            },
          ],
        }),
      );


      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply =
            data["candidates"][0]["content"]["parts"][0]["text"] ?? "No reply";

        await FirebaseFirestore.instance.collection('messages').add({
          'text': aiReply,
          'isUser': false,
          'timestamp': DateTime.now(),
        });
      } else {
        print("AI Error: ${response.body}");
      }
    } catch (e) {
      print("Error sending message: $e");
    }
  }
}
