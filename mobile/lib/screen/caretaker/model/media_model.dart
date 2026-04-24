import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { image, video }

class MediaItem {
  final String id;
  final String url;
  final MediaType type;
  final DateTime createdAt;

  MediaItem({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
  });

  factory MediaItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MediaItem(
      id: doc.id,
      url: data['url'],
      type: data['type'] == 'image' ? MediaType.image : MediaType.video,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'url': url,
      'type': type == MediaType.image ? 'image' : 'video',
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}