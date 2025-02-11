import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:messaging_app/handlers/date_time.dart';
import 'package:messaging_app/handlers/shared_prefs.dart';
import 'package:messaging_app/models/chat.dart';
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_area.dart';
import 'package:messaging_app/pages/group_page.dart';
import 'package:messaging_app/pages/login.dart';
import 'package:messaging_app/pages/user_page.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

const socketioBackendUrl = "http://192.168.0.104:5001";

class ChatListPage extends StatefulWidget {

  const ChatListPage({super.key});

  @override
  ChatListPageState createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> {
  User? currentUser;
  int? userId;

  void setCurrentUser(User newUser) {
    setState(() {
      currentUser = newUser;
    });
  }

  late IO.Socket socket;
  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset <= 0) {
        setState(() {
          _showSearchBar = true;
        });
      } else {
        setState(() {
          _showSearchBar = false;
        });
      }
    });
    performSocketConnection();
  }

  void performSocketConnection() {
    (() async {
      await connectToSocket();
    })();
  }

  Future<void> connectToSocket() async {
    socket = IO.io(socketioBackendUrl, IO.OptionBuilder()
        .setTransports(['websocket'])
        .disableAutoConnect()
        .build());

    socket.onConnect((_) {
      
    });

    socket.on('validate_token', (data) {
      final newUserId = int.parse(data['user_id'].toString());

      setState(() {
        userId = newUserId;
      });

      print("IDIDIDIDIDIDIIIDID: $userId");

      socket.emit("load_user", {"user_id": userId});
    });

    socket.on('load_user', (data) {
      print("SSSSSSSSSSSSSSSSSSSSS: $data");

      final user = User.fromJson(data['user'], includeChats: true);

      

      setState(() {
        currentUser = user;
        print("AAAAAAAAAAAAAAAAAAA: ${currentUser?.chats?.length}");
      });

      setState(() {
        isLoading = false;
      });

      socket.emit("go_online", {"user_id": userId});
    });

    socket.onDisconnect((_) {
      
    });

    socket.connect();

    String? accessToken = await getDataFromStorage("accessToken");

    if (accessToken != null) {
      socket.emit("validate_token", {"access_token": accessToken});
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

    
  }

  @override
  void dispose() {
    socket.emit("go_offline", {"user_id": userId});
    socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      return false;
    });

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
                    pageBuilder: (context, animation, secondaryAnimation) => UserProfilePage(currentUser: currentUser),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                  ),
                );
              },
              child: CircleAvatar(
                radius: 20,
                backgroundImage: AssetImage(currentUser?.profilePhotoLink ?? "assets/letter_images/u.png"),
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.group_add),
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const NewGroupPage(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOut;

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  var offsetAnimation = animation.drive(tween);

                  return SlideTransition(position: offsetAnimation, child: child);
                },
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => UserProfilePage(currentUser: currentUser,),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;

                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);

                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
              );
            },
          ),
        ],
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: _showSearchBar ? 1.0 : 0.0,
                child: Visibility(
                  visible: _showSearchBar,
                  child: Container(
                    width: 300,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        hintText: languageProvider.localizedStrings['searchUsers'] ?? "Search users",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: currentUser?.chats?.length ?? 0,
                  itemBuilder: (context, index) {
                    final chat = currentUser?.chats?[index];

                    return GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chat, currentUser: currentUser),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              const begin = Offset(1.0, 0.0);
                              const end = Offset.zero;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                              var offsetAnimation = animation.drive(tween);

                              return SlideTransition(position: offsetAnimation, child: child);
                            },
                          ),
                        );
                      },
                      child: AbsorbPointer(
                        child: ChatItem(index: index, chat: chat, currentUser: currentUser,), 
                      ),
                    );
                  },
                ),
              ),
            ],
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

class ChatItem extends StatelessWidget {
  final int index;
  final Chat chat;
  final User? currentUser;

  const ChatItem({super.key, required this.index, required this.chat, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    List<User>? otherUsers = chat.users!.where((user) => user.id != currentUser!.id).toList();
    String chatName = chat.isGroup == true ? chat.name! : otherUsers[0].name!;

    String lastmessageText = "";
    if (chat.messages!.isNotEmpty) {
      lastmessageText = chat.messages![0].text!;
    }

    String? lastmessageSendTime;
    if (chat.messages!.isNotEmpty) {
      lastmessageSendTime = formatDateTime(chat.messages![0].sendAt!);
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage(
          chat.isGroup == true ? chat.chatPhotoLink! : otherUsers[0].profilePhotoLink!
        ),
      ),
      title: Text(chatName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: chat.isGroup == true ? Container() : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat.isGroup == true ? "" : otherUsers[0].username!, 
            style: const TextStyle(color: Colors.grey, fontSize: 12)
          ),
          const SizedBox(height: 5),
          Text(
            chat.isGroup != true && otherUsers[0].isOnline! == true ? 
              languageProvider.localizedStrings["online"] ?? "Online" : "",
            style: const TextStyle(fontSize: 12, color: Colors.green),
          )
        ],
      ),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 85,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                lastmessageText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lastmessageSendTime ?? "",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (index % 3 == 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      languageProvider.localizedStrings['new'] ?? 'New',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      onTap: () {},
    );
  }
}
