import 'package:flutter/material.dart';
import 'package:messaging_app/handlers/date_time.dart';
import 'package:messaging_app/handlers/messages.dart';
import 'package:messaging_app/handlers/shared_prefs.dart';
import 'package:messaging_app/handlers/websocket.dart';
import 'package:messaging_app/models/chat.dart';
import 'package:messaging_app/models/message.dart' as Msg;
import 'package:messaging_app/models/user.dart';
import 'package:messaging_app/pages/chat_area.dart';
import 'package:messaging_app/pages/group_page.dart';
import 'package:messaging_app/pages/login.dart';
import 'package:messaging_app/pages/user_page.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:messaging_app/providers/notification_provider.dart';
import 'package:messaging_app/services/notifications_service.dart';
import 'package:provider/provider.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ChatListPage extends StatefulWidget  {

  const ChatListPage({super.key});

  @override
  ChatListPageState createState() => ChatListPageState();
}

class ChatListPageState extends State<ChatListPage> with WidgetsBindingObserver {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  int? userId;
  User? currentUser;
  int? selectedChatId;

  List<User> foundUsers = [];

  void setCurrentUser(User? user) {
    setState(() {
      currentUser = user;
    });
  }

  void updateUserOnlineStatus(int userId, bool isOnline) {
    if (currentUser?.chats == null) return;

    setState(() {
      for (var chat in currentUser!.chats!) {
        for (var user in chat.users) {
          if (user.id == userId) {
            user.isOnline = isOnline;
          }
        }
      }
    });
  }

  bool isLoading = true;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _showSearchBar = true;

  bool _backgroundServiceInitialized = false;

  Future<void> initBackgroundService() async {
    try {
      const androidConfig = FlutterBackgroundAndroidConfig(
        notificationTitle: "Socket.IO is running",
        notificationText: "Background service is active",
        notificationImportance: AndroidNotificationImportance.normal,
        notificationIcon: AndroidResource(
          name: 'background_icon',
          defType: 'drawable',
        ),
      );

      final success = await FlutterBackground.initialize(androidConfig: androidConfig);
      
      if (success) {
        setState(() {
          _backgroundServiceInitialized = true;
        });
        
        if (_backgroundServiceInitialized) {
          final isEnabled = await FlutterBackground.enableBackgroundExecution();
          if (isEnabled) {
            debugPrint('Background execution enabled successfully');
          } else {
            debugPrint('Failed to enable background execution');
          }
        }
      } else {
        debugPrint('Failed to initialize background service');
      }
    } catch (e) {
      debugPrint('Error initializing background service: $e');
    }
  }

  Future<void> enableBackgroundMode() async {
    if (!_backgroundServiceInitialized) {
      debugPrint('Cannot enable background execution: service not initialized');
      return;
    }

    try {
      final isEnabled = await FlutterBackground.enableBackgroundExecution();
      if (isEnabled) {
        debugPrint('Background execution enabled successfully');
      } else {
        debugPrint('Failed to enable background execution');
      }
    } catch (e) {
      debugPrint('Error enabling background execution: $e');
    }
  }

  late NotificationService notificationService;

  @override
  void initState() {
    super.initState();

    notificationService = NotificationService();
    (() async {
      await notificationService.requestNotificationPermission();
    })();

    WidgetsBinding.instance.addObserver(this);
    initBackgroundService();

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
    _performSocketConnection();
  }

  void _performSocketConnection() {
    (() async {
      await _connectToSocket();
    })();
  }

  Future<void> _connectToSocket() async {

    socket.on('validate_token_error', (data) {
      socket.disconnect();

      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
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
    });

    socket.on('validate_token', (data) {
      final newUserId = int.parse(data['user_id'].toString());

      setState(() {
        userId = newUserId;
      });

      socket.emit("load_user", {"user_id": userId});
    });

    socket.on("set_status", (data) {
      final isOnline = data["is_online"].toString().toLowerCase() == "true";
      final userId = data["user_id"];

      if (currentUser!.id != userId) {
        updateUserOnlineStatus(userId, isOnline);
      }

    });

    socket.on('load_user', (data) {
      final user = User.fromJson(data['user'], includeChats: true);

      setState(() {
        currentUser = user;
        isLoading = false;
      });

      socket.emit("go_online", {"user_id": currentUser!.id});

      for (Chat chat in currentUser!.chats!) {
        socket.emit("join_room", {"room": chat.id});
      }
    });

    socket.on("send_message_chat_list", (data) {
      final message = Msg.Message.fromJson(data['message']);
      final chat = Chat.fromJson(data['chat']);
      final userThatSend = User.fromJson(data['user_that_send']);
      final room = data['room'];

      User newUser = currentUser!;
      newUser.chats = [
        newUser.chats!.where((c) => c.id == room).first, 
        ...newUser.chats!.where((c) => c.id != room)
      ];
      newUser.chats![0].messages = [message];

      setState(() {
        currentUser = newUser;
      });

      // MAKE NOTIFICATION
      if (
        userThatSend.id != currentUser!.id &&
        Provider.of<NotificationProvider>(context, listen: false).isNotificationsEnabled
      ) {
        (() async {
          await notificationService.showNotification(
            chat.isGroup ?? false,
            chat.name ?? "",
            "${userThatSend.name!} ${userThatSend.surname}",
            message.text ?? ""
          );
        }) ();
      }
    });

    socket.on("delete_message_chat_list", (data) {
      final messageId = data['message_id'];
      final chatId = data['chat_id'];
      var lastChatMessage = data['last_chat_message'];

      Chat? chat = currentUser!.chats!.where((c) => c.id == chatId).first;

      if (lastChatMessage != null) {
        lastChatMessage = Msg.Message.fromJson(lastChatMessage);
        chat!.messages = [lastChatMessage];
      } else {
        chat!.messages = [];
      }

      User newUser = currentUser!;
      newUser.chats![newUser.chats!.indexOf(chat)] = chat;

      currentUser!.chats!.sort((a, b) {
        DateTime aLatest = a.messages.isNotEmpty ? a.messages.last.sendAt : a.createdAt;
        DateTime bLatest = b.messages.isNotEmpty ? b.messages.last.sendAt : b.createdAt;

        return bLatest.compareTo(aLatest);
      });

      setState(() {
        currentUser = newUser;
      });

    });

    socket.on("delete_chat_from_chats", (data) {
      final chatId = data["chat_id"];

      if (currentUser!.chats!.map((c) => c.id).toList().contains(chatId)) {
        socket.emit("leave_room", {"room": chatId});

        socket.emit("load_user_chats", {
          "user_id": currentUser!.id
        });
      }

    });

    socket.on("search_users_by_username", (data) {
      List<User> searchedUsers = (data["users"] as List).map((u) => User.fromJson(u)).toList();

      setState(() {
        foundUsers = searchedUsers;
      });
    });

    socket.on("load_user_chats", (data) {
      List<Chat> userChats = (data["user_chats"] as List).map((c) => Chat.fromJson(c)).toList();

      User user = currentUser!;
      user.chats = userChats;

      setCurrentUser(user);
    });

    socket.on("change_user_info_for_chat_list", (data) {
      final changedUserId = data["changed_user_id"];

      if (changedUserId != currentUser!.id) {
        socket.emit("load_user_chats", {
          "user_id": currentUser!.id
        });
      }
    });

    void createChatGroupHandle(data) {
      final currentUserId = data["current_user_id"];
      final users = (data["users"] as List).map((u) => User.fromJson(u)).toList();
      final userIds = users.map((u) => u.id).toList();
      final chat = Chat.fromJson(data["chat"]);

      if (currentUserId == currentUser!.id) {
        socket.emit("load_user_chats", {
          "user_id": currentUser!.id
        });

        socket.emit("join_room", {"room": chat.id});

        User user = currentUser!.deepCopy();
        user.chats = [chat, ...user.chats!];

        setState(() {
          currentUser = user;
        });

        Chat? chatWithUser = currentUser!.chats!.firstWhere(
          (c) => c.id == chat.id,
          orElse: () => null
        );

        Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chatWithUser!, currentUser: currentUser, setCurrentUser: setCurrentUser),
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

        // Navigator.of(context, rootNavigator: true).push(
        //   PageRouteBuilder(
        //     pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chat, currentUser: currentUser, setCurrentUser: setCurrentUser),
        //     transitionsBuilder: (context, animation, secondaryAnimation, child) {
        //       const begin = Offset(1.0, 0.0);
        //       const end = Offset.zero;
        //       const curve = Curves.easeInOut;

        //       var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        //       var offsetAnimation = animation.drive(tween);

        //       return SlideTransition(position: offsetAnimation, child: child);
        //     },
        //   )
        // );

        showSuccessToast(
          context, 
          Provider.of<LanguageProvider>(context, listen: false).localizedStrings["chatCreatedSuccessfully"] ?? "Chat was created successfully"
        );

      } else if (userIds.contains(currentUser!.id)) {
        socket.emit("join_room", {"room": chat.id});
        
        socket.emit("load_user_chats", {
          "user_id": currentUser!.id
        });
      }
    }

    socket.on("create_chat", createChatGroupHandle);
    socket.on("create_group_chat_list", createChatGroupHandle);
    
    socket.connect();

    String? accessToken = await getDataFromStorage("accessToken");

    if (accessToken != null) {
      socket.emit("validate_token", {"access_token": accessToken});
    } else {
      Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        socket.emit("go_online", {"user_id": currentUser!.id});

        debugPrint("App resumed, reconnecting socket...");
        _connectSocket();
        
        if (_backgroundServiceInitialized) {
          final enabled = await FlutterBackground.enableBackgroundExecution();
          if (enabled) {
            debugPrint('Background execution re-enabled');
          }
        }
        break;
        
      case AppLifecycleState.paused:
        socket.emit("go_offline", {"user_id": currentUser!.id});

        debugPrint("App paused, managing background state...");
        if (_backgroundServiceInitialized) {
          final isEnabled = FlutterBackground.isBackgroundExecutionEnabled;
          if (!isEnabled) {
            await FlutterBackground.enableBackgroundExecution();
          }
          _disconnectSocket();
        } else {
          _disconnectSocket();
        }
        break;
        
      default:
        break;
    }
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    socket.dispose();
    super.dispose();
  }

  void searchUsers(String value) {
    if (value.isEmpty) {
      setState(() {
        foundUsers = [];
      });
    } else {
      socket.emit("search_users_by_username", {
        "username_value": value
      });
    }
  }

  void openGroupChat(int chatId) {
    final userChatsIds = currentUser!.chats!.map((c) => c.id).toList();
    if (userChatsIds.contains(chatId)) {
      Chat? chatWithUser = currentUser!.chats!.firstWhere(
        (c) => c.id == chatId,
        orElse: () => null
      );

      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chatWithUser!, currentUser: currentUser, setCurrentUser: setCurrentUser),
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
    }
  }

  void startNewChat(int userId) {
    setState(() {
      foundUsers = [];
    });
    _searchController.clear();

    final userIdsList = currentUser!.chats!.where((c) => c.isGroup == false).toList().expand((chat) => chat.users).map((user) => user.id!).toSet().toList();
    if (userIdsList.contains(userId)) {
      
      Chat chatWithUser = currentUser!.chats!.where(
        (chat) => chat.isGroup == false && chat.users.map((u) => u.id).toList().contains(userId)
      ).toList()[0] as Chat;

      Navigator.of(context, rootNavigator: true).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chatWithUser, currentUser: currentUser, setCurrentUser: setCurrentUser),
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

    } else {
      socket.emit("create_chat", {
        "current_user_id": currentUser!.id,
        "user_ids": [userId],
        "is_group": false,
        "created_at": DateTime.now().toIso8601String()
      });
    }
  }

  Future<void> _connectSocket() async {
    try {
      String? accessToken = await getDataFromStorage("accessToken");
      
      if (accessToken == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
        return;
      }

      socket.off("validate_token_error");
      socket.off("validate_token");
      socket.off("set_status");
      socket.off("load_user");
      socket.off("send_message_chat_list");
      socket.off("delete_message_chat_list");
      socket.off("search_users_by_username");
      socket.off("load_user_chats");
      socket.off("change_user_info_for_chat_list");
      socket.off("create_chat");
      socket.off("create_group_chat_list");

      if (!socket.connected) {
        socket.connect();
      }

      await _connectToSocket();

      debugPrint('Socket connected and listeners set up');
    } catch (e) {
      debugPrint('Error connecting socket: $e');
    }
  }

  Future<void> _disconnectSocket() async {
  try {
    if (currentUser != null) {
      socket.emit('go_offline', {'user_id': currentUser!.id});
      
      for (Chat chat in currentUser!.chats!) {
        socket.emit('leave_room', {'room': chat.id});
      }
    }

    socket.off("validate_token_error");
    socket.off("validate_token");
    socket.off("set_status");
    socket.off("load_user");
    socket.off("send_message_chat_list");
    socket.off("delete_message_chat_list");
    socket.off("search_users_by_username");
    socket.off("load_user_chats");
    socket.off("change_user_info_for_chat_list");
    socket.off("create_chat");
    socket.off("create_group_chat_list");

    if (socket.connected) {
      socket.disconnect();
    }

    debugPrint('Socket disconnected and listeners removed');
  } catch (e) {
    debugPrint('Error disconnecting socket: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    ModalRoute.of(context)?.addScopedWillPopCallback(() async {
      return false;
    });

    var languageProvider = Provider.of<LanguageProvider>(context);
    var notificationProvider = Provider.of<NotificationProvider>(context, listen: false);

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.inversePrimary,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () async {
                    Navigator.of(context, rootNavigator: true).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => UserProfilePage(currentUser: currentUser, setCurrentUser: setCurrentUser),
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
                Navigator.of(context, rootNavigator: true).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => NewGroupPage(
                                                            currentUser: currentUser, 
                                                            setCurrentUser: setCurrentUser, 
                                                            isEditing: false, 
                                                            group: Chat(name: "", createdAt: DateTime.now(), isGroup: true), 
                                                            openGroupChat: openGroupChat),
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
                  Navigator.of(context, rootNavigator: true).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => UserProfilePage(currentUser: currentUser, setCurrentUser: setCurrentUser),
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
                          onChanged: (value) {searchUsers(value);},
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            hintText: languageProvider.localizedStrings['searchUsers'] ?? "Search users",
                            hintStyle: const TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  foundUsers = [];
                                });
                                _searchController.clear();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (foundUsers.isNotEmpty)
                    Center(
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: 80,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: foundUsers.map((user) {
                              return GestureDetector(
                                onTap: () {startNewChat(user.id!);},
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircleAvatar(
                                        radius: 25,
                                        backgroundImage: AssetImage(user.profilePhotoLink ?? "assets/letter_images/u.png"),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        user.username!,
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
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
                        final Chat chat = currentUser?.chats?[index];

                        return GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () async {
                            setState(() {
                              selectedChatId = chat.id;
                            });

                            Navigator.of(context, rootNavigator: true).push(
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => ChatPage(chat: chat, currentUser: currentUser, setCurrentUser: setCurrentUser),
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
    );
  }
}

class ChatItem extends StatelessWidget {
  final int index;
  final Chat? chat;
  final User? currentUser;

  const ChatItem({super.key, required this.index, required this.chat, required this.currentUser});

  @override
  Widget build(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    List<User>? otherUsers = chat!.users!.where((user) => user.id != currentUser!.id).toList();
    String chatName = chat!.isGroup == true ? chat!.name! : "${otherUsers[0].name!} ${otherUsers[0].surname!}";

    String lastmessageText = "";
    if (chat!.messages!.isNotEmpty) {
      lastmessageText = chat!.messages![0].text!;
    }

    String? lastmessageSendTime;
    if (chat!.messages!.length == 1 && chat!.messages![0].isHidden == false) {
      lastmessageSendTime = formatDateTime(chat!.messages![0].sendAt!);
    }

    return ListTile(
      leading: CircleAvatar(
        radius: 30,
        backgroundImage: AssetImage(
          chat!.isGroup == true ? chat!.chatPhotoLink! : otherUsers[0].profilePhotoLink!
        ),
      ),
      title: Row(
        children: [
          if (chat!.isGroup!)
            const Icon(Icons.group),
          if (chat!.isGroup!)
            const SizedBox(width: 7),
          Text(chatName, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      subtitle: chat!.isGroup == true ? Container() : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chat!.isGroup == true ? "" : otherUsers[0].username!, 
            style: const TextStyle(color: Colors.grey, fontSize: 12)
          ),
          const SizedBox(height: 5),
          Text(
            chat!.isGroup != true && otherUsers[0].isOnline! == true ? 
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
