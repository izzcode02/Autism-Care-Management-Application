import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as parser;
import 'package:autism_care_management_application/screen/parents/model/article_model.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewsApiService {
  // Google News scraping service
  Future<List<Article>> fetchGoogleNews({
    String query = 'autism+malaysia',
    int page = 1,
  }) async {
    final start = (page - 1) * 10;
    final url = 'https://www.google.com/search?q=$query&tbm=nws&start=$start';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final newsItems = document.querySelectorAll('div.SoaBEf');

        return newsItems.map((item) {
          // Improved image extraction
          final imageElement = item.querySelector('img');
          String imageUrl = imageElement?.attributes['src'] ?? '';

          // Handle Google's image proxy URLs
          if (imageUrl.startsWith('/images/branding/product/')) {
            imageUrl = ''; // Skip Google branding images
          } else if (imageUrl.startsWith('data:image')) {
            imageUrl = ''; // Skip data URIs as they might not render properly
          } else if (imageUrl.startsWith('http')) {
            // Ensure proper https
            imageUrl = imageUrl.replaceFirst('http://', 'https://');
          }

          // Extract published date - now with guaranteed fallback
          DateTime publishedAt = _parsePublishedDate(item);

          return Article(
            title: item.querySelector('div.MBeuO')?.text ?? 'No title',
            description: item.querySelector('div.GI74Re')?.text ?? '',
            urlToImage: imageUrl,
            url: _extractArticleUrl(item),
            source: item.querySelector('div.MgUUmf span')?.text ?? 'Unknown',
            publishedAt: publishedAt, // Now guaranteed to have a value
          );
        }).toList();
      } else {
        throw Exception('Google News request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Google News fetch error: $e');
    }
  }

  DateTime _parsePublishedDate(Element item) {
    final dateElement = item.querySelector('div.LfVVr');
    if (dateElement != null) {
      try {
        final dateText = dateElement.text;

        // Handle "X hours/minutes ago"
        if (dateText.contains('hour') || dateText.contains('minute')) {
          return DateTime.now();
        }
        // Handle "X days ago"
        else if (dateText.contains('day')) {
          final days = int.tryParse(dateText.split(' ')[0]) ?? 0;
          return DateTime.now().subtract(Duration(days: days));
        }
        // Handle specific date formats if available
        else if (dateText.contains(RegExp(r'\d{1,2} [A-Za-z]{3} \d{4}'))) {
          return DateFormat('d MMM yyyy').parse(dateText);
        }
      } catch (e) {
        print('Error parsing date: $e');
      }
    }
    // Fallback to current date if parsing fails
    return DateTime.now();
  }

  String _extractArticleUrl(Element item) {
    String? articleUrl = item.querySelector('a')?.attributes['href'];
    if (articleUrl == null) return '';

    if (articleUrl.startsWith('/url?')) {
      final uri = Uri.parse(articleUrl);
      return uri.queryParameters['q'] ?? '';
    }
    return articleUrl;
  }

  // Updated fetch method with Google News fallback
  Future<List<Article>> fetchEverythingNews({
    String about = 'Autism',
    String from = '2024-01-10',
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final articles = await fetchGoogleNews(
        query: '${about.replaceAll(' ', '+')}+malaysia',
        page: page,
      );

      await saveToCache(articles);
      return articles;
    } catch (e) {
      print('Primary source failed: $e');
      return await loadFromCache();
    }
  }

  Future<void> saveToCache(List<Article> articles) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(articles.map((a) => a.toJson()).toList());
    await prefs.setString('cached_articles', jsonString);
  }

  Future<List<Article>> loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('cached_articles');

    if (jsonString != null) {
      final List<dynamic> jsonData = json.decode(jsonString);
      return jsonData.map((json) => Article.fromJson(json)).toList();
    } else {
      return [];
    }
  }
}
