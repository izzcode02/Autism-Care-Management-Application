import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  // Question flow state
  int currentQuestionIndex = 0;
  Map<String, dynamic> userAnswers = {};
  bool showResults = false;

  // Mock data
  final List<Map<String, dynamic>> personalizedCenters = [
    {
      'name': 'Sunshine Autism Center',
      'location': '2.5 km away',
      'specialty': 'Specializes in toddlers with sensory needs',
      'rating': 4.8,
      'icon': Icons.sunny,
      'color': Colors.orange,
    },
    {
      'name': 'Harmony Therapy Hub',
      'location': '3.1 km away',
      'specialty': 'ABA therapy experts for ages 3-10',
      'rating': 4.6,
      'icon': Icons.music_note,
      'color': Colors.purple,
    },
  ];

  final List<Map<String, dynamic>> topRatedCenters = [
    {
      'name': 'Elite Autism Care',
      'location': '5.2 km away',
      'specialty': '5.0 rating from 128 reviews',
      'rating': 5.0,
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'name': 'Oceanview Therapy',
      'location': '7.8 km away',
      'specialty': '4.9 rating, animal-assisted therapy',
      'rating': 4.9,
      'icon': Icons.pets,
      'color': Colors.blue,
    },
  ];

  final List<Map<String, dynamic>> newlyAddedCenters = [
    {
      'name': 'New Horizons Center',
      'location': '4.3 km away',
      'specialty': 'Opened last month with swimming therapy',
      'rating': 4.5,
      'icon': Icons.new_releases,
      'color': Colors.green,
    },
  ];

  // Questions for the flow
  final List<Map<String, dynamic>> questions = [
    {
      'question': "What is your child's age?",
      'options': ['0-3 years', '3-6 years', '6-12 years', '12+ years'],
      'key': 'age'
    },
    {
      'question': "Does your child have any special needs?",
      'options': ['Non-verbal', 'Sensory-friendly', 'ADHD-compatible', 'None'],
      'key': 'needs'
    },
    {
      'question': "Preferred therapy types?",
      'options': ['ABA', 'Speech therapy', 'Occupational therapy', 'Mixed'],
      'key': 'therapy'
    },
    {
      'question': "What's your budget range?",
      'options': ['Free', 'Low-cost', 'Premium'],
      'key': 'budget'
    },
    {
      'question': "How far are you willing to travel?",
      'options': ['Within 5km', 'Within 10km', 'Any distance'],
      'key': 'distance'
    },
  ];

  void answerQuestion(String answer) {
    setState(() {
      userAnswers[questions[currentQuestionIndex]['key']] = answer;

      if (currentQuestionIndex < questions.length - 1) {
        currentQuestionIndex++;
      } else {
        // All questions answered
        showResults = true;
      }
    });
  }

  void restartQuestionnaire() {
    setState(() {
      currentQuestionIndex = 0;
      userAnswers = {};
      showResults = false;
    });
  }

  Widget _buildQuestion() {
    final currentQuestion = questions[currentQuestionIndex];
    final textTheme = Theme.of(context).textTheme;

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Column(
        children: [
          // Recommendation header (top left aligned)
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text('Recommendation', style: textTheme.headlineLarge),
            ),
          ),

          // Centered Q&A section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question text
                  Text(
                    currentQuestion['question'],
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Answer options
                  ...currentQuestion['options'].map<Widget>((option) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () => answerQuestion(option),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          option,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final textTheme = TextTheme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Gap(10),
          Text('Recommendation', style: textTheme.headlineLarge),
          // Personalized recommendations
          if (personalizedCenters.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Personalized Recommendations',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: Column(
                children: personalizedCenters.map((center) {
                  return _buildCenterCard(center);
                }).toList(),
              ),
            ),
          ],

          // Top rated
          if (topRatedCenters.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: Text(
                'Top Rated Centers Near You',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: topRatedCenters.map((center) {
                return _buildCenterCard(center);
              }).toList(),
            ),
          ],

          // Newly added
          if (newlyAddedCenters.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(top: 24.0, bottom: 16.0),
              child: Text(
                'Newly Added Centers',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: newlyAddedCenters.map((center) {
                return _buildCenterCard(center);
              }).toList(),
            ),
          ],

          // Restart button
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 30.0, bottom: 20.0),
              child: OutlinedButton(
                onPressed: restartQuestionnaire,
                child: const Text('Restart Questionnaire'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCenterCard(Map<String, dynamic> center) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: center['color'],
                  child: Icon(center['icon'], color: Colors.white),
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        center['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(center['location']),
                    ],
                  ),
                ),
                Chip(
                  label: Text('${center['rating']}'),
                  backgroundColor: Colors.grey[200],
                ),
              ],
            ),
            const Gap(10),
            Text(
              center['specialty'],
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: showResults ? _buildResults() : _buildQuestion(),
      ),
    );
  }
}
