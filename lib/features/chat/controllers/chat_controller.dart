import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:truelovebiker/core/storage/secure_storage.dart';
import 'package:truelovebiker/data/services/chat_service.dart';

class ChatController extends GetxController {
  final int pedidoId;
  ChatController({required this.pedidoId});

  final ChatService _chatService = Get.find<ChatService>();
  final messageController = TextEditingController();
  
  final messages = <Map<String, dynamic>>[].obs;
  final isLoading = true.obs;
  final senderId = 0.obs;
  
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _loadUser();
    _loadMessages();
    
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _loadMessages();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    messageController.dispose();
    super.onClose();
  }

  Future<void> _loadUser() async {
    final idUser = await SecureStorage.getUserId();
    if (idUser != null) {
      senderId.value = idUser;
    }
  }

  Future<void> _loadMessages() async {
    try {
      final newMessages = await _chatService.getMessages(pedidoId);
      messages.assignAll(newMessages);
    } catch (e) {
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty) return;

    final success = await _chatService.sendMessage(
      pedidoId: pedidoId,
      senderId: senderId.value,
      message: text,
    );

    if (success) {
      messageController.clear();
      _loadMessages();
    }
  }
}
