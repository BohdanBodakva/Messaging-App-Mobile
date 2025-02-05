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
    required this.name,
    this.surname,
    required this.username,
    String? profilePhotoLink,
    DateTime? lastSeen,
    List? chats,
    List? unreadMessages,
  })  : id = id ?? 0,
        profilePhotoLink = profilePhotoLink ?? "fff";

  // static String _getProfilePhotoLinkFromFirstLetter(String name) {
  //   if (!name.isEmpty) {
  //     String firstSymbol = name.substring(0, 1);
  //   } 

  //   return 
  // }

  // static String _validateProfilePhotoLink(int id) {
  //   if (id.isEmpty) {
  //     throw ArgumentError('ID cannot be empty');
  //   }
  //   return id;
  // }

  static String _validateName(String name) {
    if (name.isEmpty) {
      throw ArgumentError('Name cannot be empty');
    }
    if (name.length < 3) {
      throw ArgumentError('Name must be at least 3 characters long');
    }
    return name;
  }

  // @override
  // String toString() {
  //   return 'User{id: $id, name: $name, email: $email, createdAt: $createdAt}';
  // }
}
