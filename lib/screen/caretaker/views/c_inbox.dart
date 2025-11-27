import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class CaretakerInbox extends StatefulWidget {
  const CaretakerInbox({super.key});

  @override
  State<CaretakerInbox> createState() => _CaretakerInboxState();
}

class _CaretakerInboxState extends State<CaretakerInbox> {
  final caretakerController = CaretakerController();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _markAllMessagesAsRead();
  }

  Future<void> _markAllMessagesAsRead() async {
    try {
      // Get all unread messages
      final messages = await caretakerController.getUnreadMessages();
      
      // Mark each one as read
      for (final message in messages) {
        await caretakerController.readMessage(message['id'].toString());
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking messages as read: ${e.toString()}')),
      );
    }
  }

  @override
  void dispose() {
    caretakerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Inbox'),
        backgroundColor: Colors.teal,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: caretakerController.getMessageInboxStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text('No messages found'));
                }

                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return Padding(
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        children: [
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Text('Message Inbox'),
                          ),
                          const Gap(10),
                          LargeListTile(
                            title: Text(message['title'] ?? ''),
                            subtitle: Text(message['message'] ?? ''),
                            trailing: message['read'] == false
                                ? const Icon(Icons.circle,
                                    color: Colors.red, size: 12)
                                : null,
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}