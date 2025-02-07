import 'package:flutter/material.dart';
import 'package:messaging_app/providers/language_provider.dart';
import 'package:provider/provider.dart';

class ChatInfoPage extends StatelessWidget {
  const ChatInfoPage({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/letter_images/a.png'),
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(languageProvider.localizedStrings['name'] ?? "Name", "John"),
            _buildInfoRow(languageProvider.localizedStrings['surname'] ?? "Surname", "Smith"),
            _buildInfoRow(languageProvider.localizedStrings['username'] ?? "Username", "@john_smith"),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showDeleteChatDialog(context),
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

  void _showDeleteChatDialog(BuildContext context) {
    var languageProvider = Provider.of<LanguageProvider>(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(languageProvider.localizedStrings['deleteChat'] ?? "Delete Chat"),
        content: Text(languageProvider.localizedStrings['deleteChatConfirmMessage'] ?? "Are you sure you want to delete this chat?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(languageProvider.localizedStrings['cancel'] ?? "Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text(languageProvider.localizedStrings['delete'] ?? "Delete"),
          ),
        ],
      ),
    );
  }
}
