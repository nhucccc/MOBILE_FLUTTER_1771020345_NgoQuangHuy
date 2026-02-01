import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/signalr_service.dart';

class TournamentChatScreen extends StatefulWidget {
  final int tournamentId;
  final String tournamentName;

  const TournamentChatScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentChatScreen> createState() => _TournamentChatScreenState();
}

class _TournamentChatScreenState extends State<TournamentChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ApiService _apiService = ApiService();
  final SignalRService _signalRService = SignalRService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _loadChatRoom();
    _setupSignalR();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _signalRService.leaveTournamentGroup(widget.tournamentId);
    super.dispose();
  }

  Future<void> _loadChatRoom() async {
    try {
      // TODO: Implement API call to get chat room
      // final response = await _apiService.getChatRoom(widget.tournamentId);
      
      // Mock data for demo
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _messages = [
          ChatMessage(
            id: 1,
            memberName: 'Admin',
            message: 'Chào mừng các bạn đến với phòng chat giải đấu ${widget.tournamentName}!',
            createdDate: DateTime.now().subtract(const Duration(hours: 1)),
            messageType: 'system',
            isOwn: false,
          ),
          ChatMessage(
            id: 2,
            memberName: 'Nguyễn Văn A',
            message: 'Chào mọi người! Rất hào hứng cho giải đấu này.',
            createdDate: DateTime.now().subtract(const Duration(minutes: 30)),
            messageType: 'text',
            isOwn: false,
          ),
          ChatMessage(
            id: 3,
            memberName: 'Trần Thị B',
            message: 'Lịch thi đấu đã ra chưa các bạn?',
            createdDate: DateTime.now().subtract(const Duration(minutes: 15)),
            messageType: 'text',
            isOwn: false,
          ),
        ];
        _isLoading = false;
      });
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Không thể tải phòng chat: $e');
    }
  }

  void _setupSignalR() {
    _signalRService.joinTournamentGroup(widget.tournamentId);
    
    // Listen for new messages
    _signalRService.notificationStream.listen((data) {
      if (data['type'] == 'chat_message') {
        final message = ChatMessage.fromJson(data['message']);
        setState(() {
          _messages.add(message);
        });
        _scrollToBottom();
      }
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Add message to UI immediately (optimistic update)
      final tempMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        memberName: authProvider.displayName,
        message: messageText,
        createdDate: DateTime.now(),
        messageType: 'text',
        isOwn: true,
      );
      
      setState(() {
        _messages.add(tempMessage);
      });
      
      _messageController.clear();
      _scrollToBottom();
      
      // TODO: Send message to API
      // await _apiService.sendChatMessage(widget.tournamentId, messageText);
      
    } catch (e) {
      _showError('Không thể gửi tin nhắn: $e');
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chat - ${widget.tournamentName}',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              '${_messages.length} tin nhắn',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              _showParticipants();
            },
            icon: const Icon(Icons.people),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, kBottomNavigationBarHeight + 32),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
          ),
          
          // Message Input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Nhập tin nhắn...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32),
                  child: IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isSystem = message.messageType == 'system';
    
    if (isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              message.message,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: message.isOwn 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isOwn) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                message.memberName.isNotEmpty 
                    ? message.memberName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isOwn 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!message.isOwn)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      message.memberName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: message.isOwn 
                        ? const Color(0xFF2E7D32)
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    message.message,
                    style: TextStyle(
                      color: message.isOwn ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${message.createdDate.hour}:${message.createdDate.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isOwn) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFF2E7D32),
              child: Text(
                message.memberName.isNotEmpty 
                    ? message.memberName[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showParticipants() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thành viên tham gia'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.red,
                  child: Text('A', style: TextStyle(color: Colors.white)),
                ),
                title: const Text('Admin'),
                subtitle: const Text('Quản trị viên'),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFF2E7D32),
                  child: Text('N', style: TextStyle(color: Colors.white)),
                ),
                title: const Text('Nguyễn Văn A'),
                subtitle: const Text('Thành viên'),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.purple,
                  child: Text('T', style: TextStyle(color: Colors.white)),
                ),
                title: const Text('Trần Thị B'),
                subtitle: const Text('Thành viên'),
                trailing: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final int id;
  final String memberName;
  final String message;
  final DateTime createdDate;
  final String messageType;
  final bool isOwn;

  ChatMessage({
    required this.id,
    required this.memberName,
    required this.message,
    required this.createdDate,
    required this.messageType,
    required this.isOwn,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      memberName: json['memberName'] ?? '',
      message: json['message'] ?? '',
      createdDate: DateTime.parse(json['createdDate']),
      messageType: json['messageType'] ?? 'text',
      isOwn: json['isOwn'] ?? false,
    );
  }
}