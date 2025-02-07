class User {
  int? id;
  String? name;
  String? surname;
  String? username;
  String? profilePhotoLink;
  DateTime? lastSeen;
  List? chats;
  List? unreadMesssages;

  User({
    int? id,
    required String this.name,
    String? surname,
    required String this.username,
    String? profilePhotoLink,
    DateTime? lastSeen,
    List? chats,
    List? unreadMessages,
  })  : id = id ?? -1,
        surname = surname ?? "",
        profilePhotoLink = profilePhotoLink ?? "assets/letter_images/${name.isNotEmpty ? name[0] : "u"}.png",
        chats = chats ?? [],
        unreadMesssages = unreadMessages ?? [];

}
