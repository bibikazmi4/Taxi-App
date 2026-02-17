enum ChatSender { user, driver }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.createdAt,
  });
}
