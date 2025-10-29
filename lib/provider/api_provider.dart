import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

// class AiNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
//   final String apiKey =
//       "AIzaSyBbsfeUeMq7y_IEc6o5uqNWP6SC-i-ZLJw"; // apni Gemini API key daalna

//   @override
//   Future<List<Map<String, dynamic>>> build() async {
//     // Firestore se chat messages load karlo
//     final snapshot = await FirebaseFirestore.instance
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .get();

//     return snapshot.docs.map((doc) => doc.data()).toList();
//   }

//   Future<void> sendMessage(String userMessage) async {
//     final messageData = {
//       'text': userMessage,
//       'isUser': true,
//       'timestamp': DateTime.now(),
//     };

//     // Save user message
//     await FirebaseFirestore.instance.collection('messages').add(messageData);

//     // Gemini ko bhejo
//     final url = Uri.parse(
//       "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey",
//     );

//     state = const AsyncLoading();

//     try {
//       final response = await http.post(
//         url,
//         headers: {"Content-Type": "application/json"},
//         body: jsonEncode({
//           "contents": [
//             {
//               "parts": [
//                 {"text": userMessage},
//               ],
//             },
//           ],
//         }),
//       );

//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         final aiReply =
//             data["candidates"][0]["content"]["parts"][0]["text"] ?? "No reply";

//         // Save AI reply
//         await FirebaseFirestore.instance.collection('messages').add({
//           'text': aiReply,
//           'isUser': false,
//           'timestamp': DateTime.now(),
//         });

//         // Update UI
//         final updatedSnapshot = await FirebaseFirestore.instance
//             .collection('messages')
//             .orderBy('timestamp')
//             .get();

//         state = AsyncData(
//           updatedSnapshot.docs.map((doc) => doc.data()).toList(),
//         );
//       } else {
//         print(response.body);
//         state = AsyncError("AI Error: ${response.body}", StackTrace.current);
//       }
//     } catch (e, st) {
//       state = AsyncError(e, st);
//     }
//   }
// }

// final aiProvider =
//     AsyncNotifierProvider<AiNotifier, List<Map<String, dynamic>>>(() {
//       return AiNotifier();
//     });

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

      // 3️⃣ Handle API response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final aiReply =
            data["candidates"][0]["content"]["parts"][0]["text"] ?? "No reply";

        // 4️⃣ Save AI reply in Firestore
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
