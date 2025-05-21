import 'package:flutter/material.dart';
import 'package:truelovebiker/services/api.dart';
import 'package:truelovebiker/services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final int pedidoId;

  const ChatScreen({super.key, required this.pedidoId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  late int senderId;
  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final idUser = await ApiService.getUsuarioId();
    setState(() {
      senderId = idUser!;
    });
  }

  Future<void> _loadMessages() async {
    final messages = await _chatService.getMessages(widget.pedidoId);
    setState(() {
      _messages = messages;
      _isLoading = false;
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final success = await _chatService.sendMessage(
      pedidoId: widget.pedidoId,
      senderId: senderId,
      message: text,
    );

    if (success) {
      _messageController.clear();
      _loadMessages(); // recargar mensajes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[_messages.length - 1 - index];
                        final isMine = msg['sender_id'] == senderId;
                        return Align(
                          alignment:
                              isMine
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  isMine ? Colors.redAccent : Colors.grey[300],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              msg['message'],
                              style: TextStyle(
                                color: isMine ? Colors.white : Colors.black,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Escribe un mensaje...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.redAccent),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
