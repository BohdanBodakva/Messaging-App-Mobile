import 'package:flutter/material.dart';
import 'package:messaging_app/handlers/websocket.dart';
import 'package:messaging_app/models/chat.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart';

class ChatInfoPage extends StatefulWidget {
  final bool isGroup;
  final List<User>? users;
  final Chat chat;
  final Socket socket;

  const ChatInfoPage({super.key, required this.socket, required this.isGroup, required this.users, required this.chat});

  @override
  ChatInfoPageState createState() => ChatInfoPageState();
}

class ChatInfoPageState extends State<ChatInfoPage> {

  @override
  void initState() {
    super.initState();
    
    _defineWebsocketOperation();
  }

  _defineWebsocketOperation(){
    (() async {
      await _defineWebsocketEvents();
    })();
  }

  Future<void> _defineWebsocketEvents() async {
    widget.socket.on("delete_chat_from_chat_info", (data) {
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    widget.socket.off("delete_chat_from_chat_info");

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.localizedStrings['userInfo'] ?? "User Info"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(widget.isGroup ? "" : widget.users![0].profilePhotoLink!),
            ),
            const SizedBox(height: 16),
            
            if (!widget.isGroup)
              _buildInfoRow(languageProvider.localizedStrings['name'] ?? "Name", widget.users![0].name!),
            if (!widget.isGroup)
              _buildInfoRow(languageProvider.localizedStrings['surname'] ?? "Surname", widget.users![0].surname!),
            if (!widget.isGroup)
              _buildInfoRow(languageProvider.localizedStrings['username'] ?? "Username", "@${widget.users![0].username}"),

            const SizedBox(height: 20),

            if (!widget.isGroup)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async => {
                    await _showDeleteChatDialog(context, widget.socket), 
                    Navigator.pop(context),
                    Navigator.pop(context),
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(languageProvider.localizedStrings['deleteChat'] ?? "Delete Chat"),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _showDeleteChatDialog(BuildContext context, Socket socket) async {
    var languageProvider = Provider.of<LanguageProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.localizedStrings['deleteChat'] ?? "Delete Chat"),
        content: Text(languageProvider.localizedStrings['deleteChatConfirmMessage'] ?? "Are you sure you want to delete this chat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
            child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              socket.emit("delete_chat", {
                "chat_id": widget.chat.id
              });

              Navigator.pop(context);
            },
            child: Text(languageProvider.localizedStrings['delete'] ?? "Delete"),
          ),
        ],
      ),
    );
  }
}
