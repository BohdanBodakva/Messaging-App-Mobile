import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messaging_app/handlers/date_time.dart';
import 'package:messaging_app/handlers/websocket.dart';
import 'package:messaging_app/models/chat.dart';
import 'package:messaging_app/models/message.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_info_page.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  User? currentUser;

  ChatPage({super.key, required this.chat, required this.currentUser});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  bool isListening = false;
  bool isLoading = true;

  List<Message> chatHistory = [];
  final itemsCount = 15;
  int loadHistoryOffset = 0;
  bool isChatHistoryEnded = false;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late bool isGroup;
  late List<User>? otherUsers;
  late String chatName;

  @override
  void initState() {
    super.initState();
    isGroup = widget.chat.isGroup!;
    otherUsers = widget.chat.users!.where((user) => user.id != widget.currentUser!.id).toList();
    chatName = widget.chat.isGroup == true ? widget.chat.name! : otherUsers![0].name!;
    
    _loadChatHistory();

    
  }

  _loadChatHistory(){
    (() async {
      await _defineSocketEvents();
    })();
  }

  Future<void> _defineSocketEvents() async {
    socket.on("load_chat_history", (data) {
      final history = (data["chat_history"] as List).map((msg) => Message.fromJson(msg)).toList();
      final isEnd = data["is_end"].toString().toLowerCase() == "true";

      if (!mounted) return;

      setState(() {
        chatHistory = [...chatHistory, ...history];
      });

      if (isLoading) {
        setState(() {
          isLoading = false;
          loadHistoryOffset += itemsCount;
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      }

      if (isEnd) {
        setState(() {
          isChatHistoryEnded = true;
        });
      }
    });

    socket.on('send_message', (data) {
      final message = Message.fromJson(data['message']);
      final room = data['room'];

      User newUser = widget.currentUser!;
      newUser.chats = [
        newUser.chats!.where((c) => c.id == room).first, 
        ...newUser.chats!.where((c) => c.id != room)
      ];
      newUser.chats![0].messages = [message];

      if (!mounted) return;

      setState(() {
        widget.currentUser = newUser;
      });

      if (widget.chat.id == room) {
        setState(() {
          chatHistory = [...chatHistory, message];
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });
      } else {
        // MAKE NOTIFICATION
      }
      
    });

    socket.on('delete_message', (data) {
      final messageId = data['message_id'];

      setState(() {
        chatHistory = List.from(chatHistory.where((m) => m.id != messageId));
        _selectedDeleteIndex = null;
      });
    });

    socket.emit("load_chat_history", {
      "chat_id": widget.chat.id,
      "items_count": itemsCount,
      "offset": loadHistoryOffset
    });

    
  }


  int? _selectedDeleteIndex;

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      print('File picked: ${result.files.single.name}');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      print('Image picked: ${image.path}');
    }
  }

  void _handleSend() {
    if (_messageController.text.isNotEmpty) {
      String messageText = _messageController.text.trim();

      socket.emit("send_message", {
        "text": messageText,
        "sent_at": DateTime.now().toIso8601String(),
        "sent_files": [],
        "user_id": widget.currentUser!.id,
        "room": widget.chat.id
      });

      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _deleteMessage(int index) {
    socket.emit("delete_message", {
      "message_id": index,
      "room": widget.chat.id
    });
  }

  @override
  void dispose() {
    socket.off("load_chat_history");
    socket.off("send_message");
    socket.off("delete_message");

    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => ChatInfoPage(
                      isGroup: isGroup, users: otherUsers, chat: widget.chat,
                    ),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                  )
                );
              },
              child: Text(
                isGroup ? chatName : "${otherUsers![0].name} ${otherUsers![0].surname}", 
                style: const TextStyle(fontSize: 18)
              ),
            )
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            socket.off("send_message");
            socket.off("load_chat_history");

            Navigator.pop(context, true);
          },
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => ChatInfoPage(
                    isGroup: isGroup, users: otherUsers, chat: widget.chat,
                  ),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                )
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 14.0),
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(
                  isGroup ? widget.chat.chatPhotoLink! : otherUsers![0].profilePhotoLink!
                ),
              ),
            )
          )
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedDeleteIndex = null;
              });
            },
            child: Column(
              children: [
                const SizedBox(height: 5,),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: chatHistory.length,
                    itemBuilder: (context, index) {
                      return ChatMessageItem(
                        index: chatHistory[index].id!,
                        message: chatHistory[index],
                        currentUser: widget.currentUser,
                        chat: widget.chat,
                        isGroup: widget.chat.isGroup!,
                        isSelectedForDeletion: _selectedDeleteIndex == chatHistory[index].id!,
                        onDelete: () => _deleteMessage(chatHistory[index].id!),
                        onLongPress: () {
                          if (chatHistory[index].userId! == widget.currentUser!.id) {
                            setState(() {
                              _selectedDeleteIndex = chatHistory[index].id!;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: _pickFile,
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        onPressed: _pickImage,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            hintText: "${languageProvider.localizedStrings['typeMessage']}...",
                            border: const OutlineInputBorder(),
                            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          ),
                          textInputAction: TextInputAction.newline,
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _handleSend,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class ChatMessageItem extends StatelessWidget {
  final int index;
  final Message message;
  final User? currentUser;
  final bool isSelectedForDeletion;
  final VoidCallback onDelete;
  final VoidCallback onLongPress;
  final bool isMyMessage;
  final bool isGroup;
  final Chat chat;
  final User user;

  ChatMessageItem({
    super.key,
    required this.index,
    required this.message,
    required this.currentUser,
    required this.chat,
    required this.isGroup,
    required this.isSelectedForDeletion,
    required this.onDelete,
    required this.onLongPress,
  }) : isMyMessage = message.userId == currentUser!.id,
       user = chat.users!.firstWhere((user) => user.id == message.userId);

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);
    String formattedTime = formatDateTime(message.sendAt!);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: IntrinsicWidth(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelectedForDeletion
                  ? Colors.red
                  : (isMyMessage ? Colors.blueAccent : Colors.grey[300]),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: isSelectedForDeletion
                ? GestureDetector(
                    onTap: onDelete,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.delete, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          languageProvider.localizedStrings['delete'] ?? "Delete",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment:
                        isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      if (isGroup && !isMyMessage)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            "${user.name} ${user.surname}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMyMessage ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      SelectableText(
                        message.text!,
                        style: TextStyle(
                          color: isMyMessage ? Colors.white : Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            formattedTime,
                            style: TextStyle(
                              color: isMyMessage ? Colors.white70 : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
