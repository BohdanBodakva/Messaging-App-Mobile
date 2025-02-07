class SentFile {
  int? id;
  String? fileLink;
  int? messageId;

  SentFile({
    int? id,
    required String this.fileLink,
    required int this.messageId
  })  : id = id ?? -1;

}
