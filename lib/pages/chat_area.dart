import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messaging_app/models/chat.dart';
import 'package:messaging_app/models/message.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_info_page.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class ChatPage extends StatefulWidget {
  final Chat chat;
  final User? currentUser;

  const ChatPage({super.key, required this.chat, required this.currentUser});

  @override
  ChatPageState createState() => ChatPageState();
}

class ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  late bool isGroup;
  late List<User>? otherUsers;
  late String chatName;
  late List<Message> messages;

  @override
  void initState() {
    super.initState();
    isGroup = widget.chat.isGroup!;
    otherUsers = widget.chat.users!.where((user) => user.id != widget.currentUser!.id).toList();
    chatName = widget.chat.isGroup == true ? widget.chat.name! : otherUsers![0].name!;
    messages = widget.chat.messages!;
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
      String sanitizedMessage = _messageController.text.trim();
      sanitizedMessage = sanitizedMessage.replaceAll(RegExp(r'\n+'), '\n');
      // if (sanitizedMessage.isNotEmpty) {
      //   setState(() {
      //     messages.add(sanitizedMessage);
      //     isMyMessage.add(true);
      //     _messageController.clear();
      //   });
      //   _scrollToBottom();
      // }
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
    setState(() {
      messages.removeAt(index);
      // isMyMessage.removeAt(index);
      _selectedDeleteIndex = null;
    });
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
                    pageBuilder: (context, animation, secondaryAnimation) => const ChatInfoPage(),
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
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const ChatInfoPage(),
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
      body: GestureDetector(
        onTap: () {
          setState(() {
            _selectedDeleteIndex = null;
          });
        },
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {

                  return ChatMessageItem(
                    index: messages[index].id!,
                    message: messages[index],
                    currentUser: widget.currentUser,
                    chat: widget.chat,
                    isGroup: widget.chat.isGroup!,
                    isSelectedForDeletion: _selectedDeleteIndex == index,
                    onDelete: () => _deleteMessage(index),
                    onLongPress: () {
                      if (messages[index].userId! == widget.currentUser!.id) {
                        setState(() {
                          _selectedDeleteIndex = index;
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
       user = chat.users!.where((user) => user.id == message.userId).toList()[0];

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            left: isMyMessage ? 50 : 10,
            right: isMyMessage ? 10 : 50,
            top: 10,
            bottom: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isMyMessage)
                const CircleAvatar(
                  radius: 15,
                  backgroundImage: AssetImage('assets/letter_images/a.png'),
                ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelectedForDeletion ? Colors.red : (isMyMessage ? Colors.blueAccent : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isSelectedForDeletion
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: GestureDetector(
                          onTap: onDelete,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delete, color: Colors.white),
                              Text(
                                languageProvider.localizedStrings['delete'] ?? "Delete",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          isGroup && !isMyMessage ? Text(
                            "${user.name} ${user.surname}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isMyMessage ? Colors.white : Colors.black,
                              fontSize: 14,
                            ),
                          ) : Container(),
                          const SizedBox(height: 5),
                          Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.5),
                            child: SelectableText(
                              message.text!,
                              style: TextStyle(
                                color: isMyMessage ? Colors.white : Colors.black87,
                                fontSize: 16,
                              ),
                              maxLines: null,
                            ),
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
}
