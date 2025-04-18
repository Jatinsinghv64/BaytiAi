// import 'dart:convert';
// import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:http/http.dart' as http;
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class AIService {
//   static Future<Map<String, dynamic>> extractSearchParameters(
//       String query, FirebaseFirestore firestore) async {
//     final apiKey = dotenv.env['GEMINI_API_KEY'];
//     final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey');
//
//     final properties = await firestore.collection('properties').get();
//     final propertyTypes = properties.docs
//         .map((doc) => doc['propertyType'].toString())
//         .toSet()
//         .toList();
//
//     final prompt = '''
//     Extract real estate search parameters from this query: "$query"
//     Available property types: ${propertyTypes.join(', ')}
//
//     Respond STRICTLY in this JSON format:
//     {
//       "type": "property type or null",
//       "minBedrooms": number or null,
//       "maxPrice": number or null,
//       "location": "string or null",
//       "amenities": ["array", "of", "strings"] or null
//     }
//
//     Example: For "3 bed villa in Doha under 10,000 with pool" respond with:
//     {
//       "type": "villa",
//       "minBedrooms": 3,
//       "maxPrice": 10000,
//       "location": "Doha",
//       "amenities": ["pool"]
//     }
//     ''';
//
//     final response = await http.post(
//       url,
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({
//         'contents': [{
//           'role': 'user',
//           'parts': [{'text': prompt}]
//         }],
//         'generationConfig': {
//           'temperature': 0.2, // Very low temperature for strict formatting
//           'maxOutputTokens': 300,
//           'response_mime_type': 'application/json'
//         }
//       }),
//     );
//
//     if (response.statusCode == 200) {
//       final responseBody = jsonDecode(response.body);
//       final textResponse = responseBody['candidates'][0]['content']['parts'][0]['text'];
//       return jsonDecode(textResponse);
//     } else {
//       throw Exception('API Error: ${response.statusCode} - ${response.body}');
//     }
//   }
// }