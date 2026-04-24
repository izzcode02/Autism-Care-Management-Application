import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ParentsMapsInbox extends StatefulWidget {
  const ParentsMapsInbox({super.key});

  @override
  State<ParentsMapsInbox> createState() => _ParentsMapsInboxState();
}

class _ParentsMapsInboxState extends State<ParentsMapsInbox> {
  final parentController = FirestoreService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _markAllMessagesAsRead();
  }

  Future<void> _markAllMessagesAsRead() async {
    try {
      // First load messages to ensure we have data
      final initialMessages = await parentController.getMessageInbox();
      
      // Filter only unread messages with valid IDs
      final unreadMessages = initialMessages.where((message) => 
          message['read'] == false && message['id'] != null).toList();

      if (unreadMessages.isEmpty) {
        setState(() => isLoading = false);
        return;
      }

      // Use batch update for better performance
      final batch = FirebaseFirestore.instance.batch();
      final parentId = await parentController.getParentIdOnly();
      
      for (final message in unreadMessages) {
        final docRef = FirebaseFirestore.instance
            .collection('parents')
            .doc(parentId)
            .collection('notifications')
            .doc(message['id']);
        
        batch.update(docRef, {'read': true});
      }

      await batch.commit();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating messages: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    parentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _markAllMessagesAsRead,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: parentController.getMessageInboxStream(),
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
                          Align(
                            alignment: Alignment.topLeft,
                            child: Text(
                              'Message Inbox',
                              style: textTheme.headlineMedium,
                            ),
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