// views/review_section.dart
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/parents/controllers/parents_controller.dart';
import 'package:autism_care_management_application/screen/parents/model/review_model..dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class ReviewSection extends StatefulWidget {
  final String caretakerId;
  final String currentUserId;
  final String currentUserName;

  const ReviewSection({
    Key? key,
    required this.caretakerId,
    required this.currentUserId,
    required this.currentUserName,
  }) : super(key: key);

  @override
  _ReviewSectionState createState() => _ReviewSectionState();
}

class _ReviewSectionState extends State<ReviewSection> {
  late FirestoreService _reviewController;
  List<Review> reviews = [];
  Review? _userReview;
  bool isLoading = true;
  final TextEditingController _commentController = TextEditingController();
  int _currentRating = 0;

  @override
  void initState() {
    super.initState();
    _reviewController = FirestoreService();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() => isLoading = true);

    // Load all reviews and user's specific review
    final allReviews = await _reviewController.getReviewsForCaretaker(
        widget.caretakerId, widget.currentUserId);

    _userReview = await _reviewController.getUserReview(
        widget.caretakerId, widget.currentUserId);

    setState(() {
      reviews = allReviews;
      if (_userReview != null) {
        _commentController.text = _userReview!.comment;
        _currentRating = _userReview!.rating;
      }
      isLoading = false;
    });
  }

  Future<void> _submitReview() async {
    if (_currentRating == 0 || _commentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide both rating and comment')),
      );
      return;
    }

    final success = await _reviewController.addOrUpdateReview(
      caretakerId: widget.caretakerId,
      reviewerId: widget.currentUserId,
      reviewerName: widget.currentUserName,
      rating: _currentRating,
      comment: _commentController.text,
    );

    if (success) {
      await _loadReviews();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_userReview == null
                ? 'Review added successfully'
                : 'Review updated successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to submit review')),
      );
    }
  }

  double _calculateAverageRating(List<Review> reviews) {
    if (reviews.isEmpty) return 0.0;

    final totalRating = reviews.fold(0.0, (sum, review) => sum + review.rating);
    final average = totalRating / reviews.length;

    // Round to 1 decimal place
    return double.parse(average.toStringAsFixed(1));
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Review'),
        content: const Text('Are you sure you want to delete this review?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _reviewController.deleteReview(
        widget.caretakerId,
        reviewId,
        widget.currentUserId,
      );

      if (success) {
        _commentController.clear();
        _currentRating = 0;
        await _loadReviews();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to delete review or not authorized')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text('Total Rating'),
            Gap(2),
            Icon(
              Icons.star,
              size: 18,
              color: Colors.amber,
            ),
            Gap(5),
            Text(
              ': ${_calculateAverageRating(reviews)} / 5.0 (${reviews.length} ${reviews.length == 1 ? 'review' : 'reviews'})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        // Review Form
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userReview == null
                      ? 'Add Your Review'
                      : 'Update Your Review',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < _currentRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentRating = index + 1;
                        });
                      },
                    );
                  }),
                ),
                TextField(
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(250),
                  ],
                  controller: _commentController,
                  decoration: const InputDecoration(
                    hintText: 'Write your review here...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: _submitReview,
                    child: Text(_userReview == null
                        ? 'Submit Review'
                        : 'Update Review'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Reviews List
        if (isLoading)
          const Center(child: CustomLoader())
        else if (reviews.isEmpty)
          const Text('No reviews yet. Be the first to review!')
        else
          SizedBox(
            height: 250,
            child: PageView.builder(
              itemCount: reviews.length,
              itemBuilder: (context, index) {
                final review = reviews[index];
                final isCurrentUserReview =
                    review.reviewerId == widget.currentUserId;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header row with name, date, and delete button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  review.reviewerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMMM d, y')
                                      .format(DateTime.parse(review.date)),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isCurrentUserReview)
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.delete, size: 18),
                              color: Colors.red,
                              onPressed: () => _deleteReview(review.reviewId),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Star rating
                      Row(
                        children: List.generate(5, (starIndex) {
                          return Icon(
                            starIndex < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      // Review comment
                      Flexible(
                        fit: FlexFit
                            .loose, // Allows the child to determine its own size
                        child: Text(
                          review.comment,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      // Caretaker feedback if available
                      if (review.feedbackMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              'Caretaker: ${review.feedbackMessage}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[800],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
