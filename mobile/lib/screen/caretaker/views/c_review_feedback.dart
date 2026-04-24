import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/caretaker/controllers/caretaker_controller.dart';
import 'package:autism_care_management_application/screen/caretaker/model/parents_model.dart';
import 'package:autism_care_management_application/screen/caretaker/model/review_model..dart';
import 'package:autism_care_management_application/utils/drawer_layout.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CaretakerFeedbackReview extends StatefulWidget {
  const CaretakerFeedbackReview({super.key});

  @override
  State<CaretakerFeedbackReview> createState() =>
      _CaretakerFeedbackReviewState();
}

class _CaretakerFeedbackReviewState extends State<CaretakerFeedbackReview> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviewsWithParents = [];
  final TextEditingController _feedbackController = TextEditingController();
  final caretakerController = CaretakerController();
  String _caretakerName = 'Company Name';

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadCaretakerName();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _reviewsWithParents =
          await caretakerController.getCaretakerReviewsWithParents();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading reviews: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadCaretakerName() async {
    try {
      final caretaker = await caretakerController.getCaretaker();
      if (caretaker != null) {
        setState(() {
          _caretakerName = caretaker.name;
        });
      }
    } catch (e) {
      debugPrint('Error loading caretaker name: $e');
    }
  }

  // Calculate overall rating
  double _calculateOverallRating() {
    if (_reviewsWithParents.isEmpty) return 0.0;

    double totalRating = 0.0;
    for (var data in _reviewsWithParents) {
      final review = data['review'] as Review;
      totalRating += review.rating;
    }
    return totalRating / _reviewsWithParents.length;
  }

  // Get rating percentage
  double _getRatingPercentage() {
    return (_calculateOverallRating() / 5.0) * 100;
  }

  // Build star rating widget
  Widget _buildStarRating(double rating) {
    List<Widget> stars = [];
    int fullStars = rating.floor();
    double remainder = rating - fullStars;

    // Add full stars
    for (int i = 0; i < fullStars; i++) {
      stars.add(Icon(Icons.star, color: Colors.amber, size: 30));
    }

    // Add half star if needed
    if (remainder >= 0.5) {
      stars.add(Icon(Icons.star_half, color: Colors.amber, size: 30));
      fullStars++;
    }

    // Add empty stars
    for (int i = fullStars; i < 5; i++) {
      stars.add(Icon(Icons.star_outline, color: Colors.grey, size: 30));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }

  // Build overall rating display
  Widget _buildOverallRatingDisplay() {
    if (_reviewsWithParents.isEmpty) {
      return Column(
        children: [
          Text(
            'No ratings yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          _buildStarRating(0),
          Text('0%', style: Theme.of(context).textTheme.titleLarge),
        ],
      );
    }

    double overallRating = _calculateOverallRating();
    double percentage = _getRatingPercentage();

    return Column(
      children: [
        Text(
          '${overallRating.toStringAsFixed(1)}/5.0',
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
        ),
        Gap(8),
        _buildStarRating(overallRating),
        Gap(8),
        Text(
          '${percentage.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.green[600],
              ),
        ),
        Gap(4),
        Text(
          'Based on ${_reviewsWithParents.length} review${_reviewsWithParents.length == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  Future<void> _showFeedbackDialog(Review review) async {
    final existingFeedback =
        await caretakerController.getReviewFeedback(review.reviewId);
    _feedbackController.text = existingFeedback?.feedbackMessage ?? '';

    final textTheme = Theme.of(context).textTheme;
    final screenSize = MediaQuery.sizeOf(context);

    await AwesomeDialog(
      width: screenSize.width * 0.7,
      context: context,
      dialogType: DialogType.info,
      animType: AnimType.bottomSlide,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          children: [
            Text(
              'Reply Feedback',
              style: textTheme.headlineLarge,
            ),
            Gap(10),
            TextField(
              controller: _feedbackController,
              decoration: const InputDecoration(
                hintText: 'Enter your feedback...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
      btnCancel: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel', style: TextStyle(color: Colors.white)),
      ),
      btnOk: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        onPressed: () async {
          if (_feedbackController.text.isEmpty) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              title: 'Empty Feedback',
              desc: 'Please enter your feedback before submitting.',
              btnOkOnPress: () {},
            ).show();
            return;
          }

          final success = await caretakerController.sendFeedback(
            reviewId: review.reviewId,
            feedbackMessage: _feedbackController.text,
          );

          if (mounted) {
            Navigator.pop(context);
            if (success) {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.success,
                animType: AnimType.bottomSlide,
                title: 'Success',
                desc: 'Feedback submitted successfully!',
                btnOkOnPress: () {},
              ).show();
              await _loadData();
            } else {
              AwesomeDialog(
                context: context,
                dialogType: DialogType.error,
                title: 'Error',
                desc: 'Failed to submit feedback. Please try again.',
                btnOkOnPress: () {},
              ).show();
            }
          }
        },
        child: const Text('Submit', style: TextStyle(color: Colors.white)),
      ),
      btnCancelText: 'Cancel',
      btnOkText: 'Submit',
    ).show();
  }

  Widget _buildLoadingList() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => LargeListTile(
        leading: CircleAvatar(),
        title: Text('Loading...'),
        subtitle: Text('Loading...'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DrawerLayout(
      title: 'Feedback and Review',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                _caretakerName.isNotEmpty
                    ? '$_caretakerName'
                    : 'Name of Autism Centre',
                style: textTheme.headlineLarge,
              ),
            ),
            Gap(16),
            // Enhanced Overall Rating Display
            Align(
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _buildOverallRatingDisplay(),
              ),
            ),
            Gap(24),
            Text(
              'Reviews from Parents',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadData,
                child: Skeletonizer(
                  enabled: _isLoading,
                  child: _isLoading
                      ? _buildLoadingList()
                      : _reviewsWithParents.isEmpty
                          ? Center(
                              child: Text(
                                'No reviews found',
                                style: textTheme.bodyLarge,
                              ),
                            )
                          : Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: ListView.builder(
                                itemCount: _reviewsWithParents.length,
                                itemBuilder: (context, index) {
                                  final data = _reviewsWithParents[index];
                                  final review = data['review'] as Review;
                                  final parent = data['parent'] as Parent;
                                  final iteration = (index + 1).toString();

                                  return LargeListTile(
                                    leading: Text(iteration),
                                    title: Text(
                                      'Parent: ${parent.name}',
                                      style: textTheme.bodyLarge,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Rating: ',
                                              style: textTheme.bodyMedium,
                                            ),
                                            ...List.generate(5, (starIndex) {
                                              return Icon(
                                                starIndex < review.rating
                                                    ? Icons.star
                                                    : Icons.star_outline,
                                                color: starIndex < review.rating
                                                    ? Colors.amber
                                                    : Colors.grey,
                                                size: 16,
                                              );
                                            }),
                                            Text(
                                              ' (${review.rating}/5)',
                                              style: textTheme.bodySmall,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          'Review: ${review.comment}',
                                          style: textTheme.bodyMedium,
                                        ),
                                        if (review.feedbackMessage != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              'Your Feedback: ${review.feedbackMessage}',
                                              style: textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontStyle: FontStyle.italic,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.feedback),
                                      onPressed: () =>
                                          _showFeedbackDialog(review),
                                    ),
                                  );
                                },
                              ),
                            ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }
}
