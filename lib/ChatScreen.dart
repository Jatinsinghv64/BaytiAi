import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'PropertyDetails.dart';

class PropertyChatScreen extends StatefulWidget {
  const PropertyChatScreen({super.key});

  @override
  State<PropertyChatScreen> createState() => _PropertyChatScreenState();
}

class _PropertyChatScreenState extends State<PropertyChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _showPropertyResults = false;
  List<DocumentSnapshot> _filteredProperties = [];
  bool _isTyping = false;
  final NumberFormat _priceFormat = NumberFormat.currency(symbol: '\$');
  final List<Map<String, dynamic>> _conversationHistory = [];

  @override
  void initState() {
    super.initState();
    _addBotMessage(
      "Hello! I'm your AI real estate assistant. How can I help you find your perfect property today?\n\n"
          "You can ask me:\n"
          "- \"Show me 3 bedroom villas with pools\"\n"
          "- \"Find apartments under 300,000 QAR in doha\"\n"
          "- \"What luxury properties do you have?\"",
      isGreeting: true,
    );
  }

  @override
  void dispose() {
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String message, {bool isGreeting = false}) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: message,
          isUser: false,
          timestamp: DateTime.now(),
          isGreeting: isGreeting,
        ),
      );
      _conversationHistory.add({'role': 'model', 'content': message});
    });
    _scrollToBottom();
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.insert(
        0,
        ChatMessage(
          text: message,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _conversationHistory.add({'role': 'user', 'content': message});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final userMessage = _chatController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _isLoading = true;
      _showPropertyResults = false;
    });

    _addUserMessage(userMessage);
    _chatController.clear();

    try {
      final aiResponse = await _getAIResponse(userMessage);
      final parsed = jsonDecode(aiResponse) as Map<String, dynamic>;

      // Decide if this is a property search or just a chat reply
      if (parsed['searchParams'] != null &&
          parsed['searchParams'] is Map &&
          (parsed['searchParams'] as Map).isNotEmpty) {
        setState(() => _isTyping = true);
        _filteredProperties = await _searchProperties(aiResponse);
        setState(() {
          _showPropertyResults = _filteredProperties.isNotEmpty;
          _isTyping = false;
        });

        if (_filteredProperties.isEmpty) {
          _addBotMessage(
            "I couldn't find properties matching your criteria. Try adjusting your search.",
          );
        } else {
          // First, show the friendly text from the AI
          _addBotMessage(parsed['response']);
          // Then show the header for the property cards
          _addBotMessage("Here are ${_filteredProperties.length} matching properties:");
        }
      } else {
        // Non-search reply: only display the AI's "response" field
        _addBotMessage(parsed['response']);
      }
    } catch (e) {
      _addBotMessage("Sorry, I'm having trouble responding. Please try again.");
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getAIResponse(String prompt) async {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final propertyTypesSnapshot =
    await _firestore.collection('properties').get();
    final propertyTypes = propertyTypesSnapshot.docs
        .map((doc) => doc['propertyType'].toString())
        .toSet()
        .toList();

    final systemPrompt = '''
You're a warm, conversational real estate assistant focused on helping people find properties in Qatar. 

Key parameters to consider:
- Property type (${propertyTypes.join(', ')})
- Price/Rent ranges
- Bedrooms/bathrooms
- Location areas
- Amenities (pool, gym, beachfront, etc.)
- Construction year
- Property size (sqm)
- Garage availability
- Developer names

Understand synonyms and related terms:
- "Near beach" = beachfront
- "New construction" = yearBuilt > 2022
- "Studio" = bedrooms = 0
- "Penthouse" = apartment with luxury amenities

Example response:
{
  "response": "I found modern 2-bed apartments in Lusail with beach access",
  "searchParams": {
    "propertyType": "apartment",
    "minBedrooms": 2,
    "maxPrice": 3000000,
    "location": "Lusail",
    "amenities": ["beachfront"],
    "minYearBuilt": 2020,
    "hasGarage": true
  }
}
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'role': 'user',
              'parts': [
                {'text': systemPrompt}
              ]
            },
            ..._conversationHistory.map((msg) => {
              'role': msg['role'],
              'parts': [
                {'text': msg['content']}
              ]
            }),
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                  'STRICTLY respond in JSON format as instructed. $prompt'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 500,
            'response_mime_type': 'application/json'
          }
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final textResponse =
        responseBody['candidates'][0]['content']['parts'][0]['text'];
        // Validate proper JSON
        jsonDecode(textResponse);
        return textResponse;
      } else {
        throw Exception('API Error: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in _getAIResponse: $e');
      return '''
{
  "response": "I encountered an error processing your request. Please try again.",
  "searchParams": null
}
''';
    }
  }

  Future<List<DocumentSnapshot>> _searchProperties(String aiResponse) async {
    try {
      final jsonResponse = jsonDecode(aiResponse);
      final searchParams = jsonResponse['searchParams'] as Map<String, dynamic>;
      Query query = _firestore.collection('properties');

      // Property Type
      if (searchParams['propertyType'] != null) {
        query = query.where('propertyType', isEqualTo: searchParams['propertyType']);
      }

      // Price/Rent Handling
      if (searchParams['maxPrice'] != null) {
        query = query.where('price', isLessThanOrEqualTo: searchParams['maxPrice']);
      }
      if (searchParams['maxRent'] != null) {
        query = query.where('rent', isLessThanOrEqualTo: searchParams['maxRent']);
      }

      // Numeric Ranges
      _applyRange(query, 'bedrooms', searchParams);
      _applyRange(query, 'bathrooms', searchParams);
      _applyRange(query, 'yearBuilt', searchParams);
      _applyRange(query, 'propertySize', searchParams);

      // Location
      if (searchParams['location'] != null) {
        query = query.where('location', isEqualTo: searchParams['location'].toString().toLowerCase());
      }

      // Amenities
      if (searchParams['amenities'] != null) {
        final amenities = List<String>.from(searchParams['amenities']);
        query = query.where('amenities', arrayContainsAny: amenities);
      }

      // Boolean Filters
      if (searchParams['hasGarage'] != null) {
        query = query.where('garage', isEqualTo: searchParams['hasGarage']);
      }

      // Developer
      if (searchParams['developer'] != null) {
        query = query.where('developedBy', isEqualTo: searchParams['developer']);
      }

      final snapshot = await query.get();
      return snapshot.docs;
    } catch (e) {
      debugPrint("Search error: $e");
      return [];
    }
  }

  void _applyRange(Query query, String field, Map<String, dynamic> params) {
    if (params['min$field'] != null) {
      query = query.where(field, isGreaterThanOrEqualTo: params['min$field']);
    }
    if (params['max$field'] != null) {
      query = query.where(field, isLessThanOrEqualTo: params['max$field']);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BaytiAi',style: TextStyle(color: Color(0xff1150ab)),),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _addBotMessage(
                "I can help you:\n"
                    "- Search properties by type, price, location\n"
                    "- Compare property features\n"
                    "- Provide details about listings\n"
                    "Try: 'Show me luxury villas with pools in Miami'",
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[50]!, Colors.white],
                ),
              ),
              child: CustomScrollView(
                reverse: true,
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding:
                    const EdgeInsets.only(top: 16, bottom: 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          if (index == 0 && _showPropertyResults) {
                            return _buildPropertyResults();
                          }
                          final messageIndex =
                          _showPropertyResults ? index - 1 : index;
                          if (messageIndex >= _messages.length)
                            return null;
                          return _buildChatBubble(
                              _messages[messageIndex]);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Searching properties...'),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message) {
    return Container(
      margin:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[50],
                child: const Icon(Icons.home_work,
                    size: 16, color: Colors.blue),
              ),
            ),
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? Colors.blue[600]
                        : (message.isGreeting
                        ? Colors.blue[50]
                        : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(
                          message.isUser ? 18 : 0),
                      bottomRight: Radius.circular(
                          message.isUser ? 0 : 18),
                    ),
                    boxShadow: [
                      if (!message.isUser && !message.isGreeting)
                        BoxShadow(
                          color:
                          Colors.black.withOpacity(0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 15,
                      color: message.isUser
                          ? Colors.white
                          : Colors.black87,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('h:mm a')
                      .format(message.timestamp),
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          if (message.isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.black12,
                child: Icon(Icons.person,
                    size: 16, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPropertyResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Text(
            'Matching Properties (${_filteredProperties.length})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
            const EdgeInsets.symmetric(horizontal: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: _filteredProperties.length,
            itemBuilder: (context, index) {
              return Container(
                width: 260,
                margin:
                const EdgeInsets.only(right: 16, bottom: 16),
                child: _buildPropertyCard(
                    _filteredProperties[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPropertyCard(DocumentSnapshot property) {
    final data = property.data() as Map<String, dynamic>;
    final price = _priceFormat.format(data['price'] ?? 0);
    final bedrooms = data['bedrooms'] ?? 0;
    final bathrooms = data['bathrooms'] ?? 0;
    final location = data['location'] ?? '';
    final title = data['title'] ?? 'No Title';
    final imageUrl = data['imageUrl'] ?? data['agentImageUrl'] ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PropertyDetailScreen(property: property),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: 260,
            maxHeight: 300,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Container(
                  color: Colors.grey[200],
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation(Colors.blue[300]!),
                      ),
                    ),
                    errorWidget: (context, url, error) => Center(
                      child: Icon(Icons.home,
                          size: 50, color: Colors.grey[400]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        Row(
                          children: [
                            _buildAmenityIcon(
                                Icons.king_bed, '$bedrooms'),
                            const SizedBox(width: 8),
                            _buildAmenityIcon(
                                Icons.bathtub, '$bathrooms'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16,
                            color: Colors.blue[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityIcon(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Ask about properties...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 15),
                      maxLines: null,
                      onSubmitted: (value) => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xff1150ab),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isGreeting;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isGreeting = false,
  });
}
