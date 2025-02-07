class Chat {
  int? id;
  String? name;
  DateTime? createdAt;
  int? adminId;
  List? users;
  String? chatPhotoLink;
  bool? isGroup;
  List? messages;

  Chat({
    int? id,
    required String this.name,
    required DateTime this.createdAt,
    int? adminId,
    List? users,
    String? chatPhotoLink,
    required bool this.isGroup,
    List? messages
  })  : id = id ?? -1,
        adminId = adminId ?? -1,
        users = users ?? [],
        chatPhotoLink = chatPhotoLink ?? "assets/letter_images/${name.isNotEmpty ? name[0] : "c"}.png",
        messages = messages ?? [];

}
