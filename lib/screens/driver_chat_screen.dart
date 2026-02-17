import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../utils/constants.dart';

class DriverChatScreen extends StatefulWidget {
  final String threadId;
  final String driverName;

  const DriverChatScreen({
    super.key,
    required this.threadId,
    required this.driverName,
  });

  @override
  State<DriverChatScreen> createState() => _DriverChatScreenState();
}

class _DriverChatScreenState extends State<DriverChatScreen> {
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().ensureThread(widget.threadId, driverName: widget.driverName);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final messages = context.watch<ChatProvider>().messagesFor(widget.threadId);

    return Scaffold(
      appBar: AppBar(title: Text("Chat • ${widget.driverName}")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(Constants.defaultPadding),
                itemCount: messages.length,
                itemBuilder: (context, i) => _Bubble(msg: messages[i], cs: cs),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(Constants.defaultPadding, 10, Constants.defaultPadding, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(context),
                      decoration: const InputDecoration(
                        hintText: "Type a message…",
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _send(context),
                    icon: const Icon(Icons.send),
                    color: cs.primary,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void _send(BuildContext context) {
    final text = _ctrl.text;
    _ctrl.clear();
    context.read<ChatProvider>().sendUserMessage(widget.threadId, text, driverName: widget.driverName);
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage msg;
  final ColorScheme cs;

  const _Bubble({required this.msg, required this.cs});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.sender == ChatSender.user;
    final bg = isMe ? cs.primaryContainer : cs.surfaceContainerHighest;
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(msg.text),
          ),
        ],
      ),
    );
  }
}
