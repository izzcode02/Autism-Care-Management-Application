//Model
class Article {
  final String title;
  final String description;
  final String urlToImage;
  final String url;
  final String? source;
  final DateTime? publishedAt;

  const Article({
    required this.title,
    required this.description,
    required this.urlToImage,
    required this.url,
    this.source,
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String? ?? 'Tiada Tajuk',
      description: json['description'] as String? ?? 'Tiada Penerangan',
      urlToImage: json['urlToImage'] as String? ?? 'https://via.placeholder.com/150',
      url: json['url'] as String? ?? '',
      source: json['source'] is String 
          ? json['source'] 
          : json['source']?['name'] as String?,
      publishedAt: json['publishedAt'] != null 
          ? DateTime.tryParse(json['publishedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'urlToImage': urlToImage,
      'url': url,
      'source': {'name': source},
      'publishedAt': publishedAt?.toIso8601String(),
    };
  }
}