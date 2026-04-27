import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../services/ai_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content': 'Hello Margaret! I am your Health Companion. You can ask me anything about your medications, medical conditions, or general health advice. How can I help you today?'
    }
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    String userMessage = _messageController.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'content': userMessage});
      _isLoading = true;
    });
    _messageController.clear();

    final healthController = Get.find<HealthController>();
    String response = await AiService.askAi(userMessage, healthController.patient.value);

    setState(() {
      _messages.add({'role': 'assistant', 'content': response});
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AI Health Chat'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                bool isUser = _messages[index]['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 15),
                    padding: const EdgeInsets.all(16),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF0066CC) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      _messages[index]['content']!,
                      style: TextStyle(
                        fontSize: 18,
                        color: isUser ? Colors.white : const Color(0xFF1E293B),
                        height: 1.4,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(10.0),
              child: Text('Health Companion is thinking...', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 18),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 10),
                CircleAvatar(
                  backgroundColor: const Color(0xFF0066CC),
                  radius: 25,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
