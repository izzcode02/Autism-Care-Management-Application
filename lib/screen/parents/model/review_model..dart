  // models/review.dart
  class Review {
    final String reviewId;
    final String caretakerId;
    final String reviewerId;
    final String reviewerName;
    final String date;
    final int rating;
    final String comment;
    final String? feedbackId;       // Optional field
    final String? feedbackMessage;  // Optional field

    Review({
      required this.reviewId,
      required this.caretakerId,
      required this.reviewerId,     
      required this.reviewerName,
      required this.date,
      required this.rating,
      required this.comment,
      this.feedbackId,              // Optional in constructor
      this.feedbackMessage,         // Optional in constructor
    });

    factory Review.fromMap(Map<String, dynamic> map) {
      return Review(
        reviewId: map['reviewId'] ?? '',
        caretakerId: map['caretakerId'] ?? '',
        reviewerId: map['reviewerId'] ?? '',
        reviewerName: map['reviewerName'] ?? 'Anonymous',
        date: map['date'] ?? '',
        rating: map['rating']?.toInt() ?? 0,
        comment: map['comment'] ?? '',
        feedbackId: map['feedbackId'],              // Will be null if not present
        feedbackMessage: map['feedbackMessage'],    // Will be null if not present
      );
    }

    Map<String, dynamic> toMap() {
      return {
        'reviewId': reviewId,
        'caretakerId': caretakerId,
        'reviewerId': reviewerId,
        'reviewerName': reviewerName,
        'date': date,
        'rating': rating,
        'comment': comment,
        'feedbackId': feedbackId,              // Included only if not null
        'feedbackMessage': feedbackMessage,     // Included only if not null
      };
    }
  }