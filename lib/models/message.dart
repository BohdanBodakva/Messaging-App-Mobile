import 'package:messaging_app/models/sent_file.dart';
import 'package:messaging_app/models/user.dart';

class Message {
  int? id;
  String? text;
  List? sentFiles;
  DateTime? sendAt;
  List? usersThatUnread;
  int? userId;
  int? chatId;

  Message({
    int? id,
    required String this.text,
    List? sentFiles,
    required DateTime this.sendAt,
    List? usersThatUnread,
    int? userId,
    required int this.chatId,
  })  : id = id ?? -1,
        sentFiles = sentFiles ?? [],
        usersThatUnread = usersThatUnread ?? [],
        userId = userId ?? -1;

}
