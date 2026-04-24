import 'dart:async';
import 'package:autism_care_management_application/common/widgets/custom_loader.dart';
import 'package:autism_care_management_application/screen/parents/controllers/newsapiservice.dart';
import 'package:autism_care_management_application/screen/parents/model/article_model.dart';
import 'package:autism_care_management_application/common/widgets/largelisttile.dart';
import 'package:autism_care_management_application/screen/parents/views/p_news_web_view.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:intl/intl.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({
    super.key,
  });

  @override
  _NewsScreenState createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  final newsApiService = NewsApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  bool isLastPage = false;
  int currentPage = 1;
  final int pageSize = 10;
  bool isLoadingMore = false;

  List<Article> allArticles = [];
  List<Article> filterArticles = [];
  late Future<void> futureInitialLoad;

  // Date filter variables
  DateTime? _selectedFromDate;
  DateTime? _selectedToDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  // Add error handling UI
  bool loadError = false;

  // Track loaded articles to prevent skeleton re-loading
  final Set<String> _loadedArticles = <String>{};

  @override
  void initState() {
    super.initState();
    futureInitialLoad = fetchInitialArticles();
    _scrollController.addListener(_scrollListener);
  }

  Future<void> fetchInitialArticles() async {
    try {
      setState(() => loadError = false);
      final articles = await newsApiService.fetchEverythingNews(
        page: currentPage,
        pageSize: pageSize,
      );

      if (!mounted) return;
      setState(() {
        allArticles = articles;
        filterArticles = List.from(allArticles);
        isLastPage = articles.length < pageSize;
        currentPage++;
      });
    } catch (e) {
      print('Fetch error: $e');
      if (!mounted) return;
      setState(() => loadError = true);
    }
  }

  Future<void> loadMoreArticles() async {
    if (isLastPage || isLoadingMore) return;
    setState(() => isLoadingMore = true);

    try {
      final newArticles = await newsApiService.fetchEverythingNews(
        page: currentPage,
        pageSize: pageSize,
      );
      if (newArticles.length < pageSize) isLastPage = true;

      if (!mounted) return;
      setState(() {
        allArticles.addAll(newArticles);
        filterArticles = List.from(allArticles);
        currentPage++;
      });
    } catch (e) {
      print('Error loading more articles: $e');
      if (mounted) {
        // Optionally handle error state here
      }
    } finally {
      if (!mounted) return;
      setState(() => isLoadingMore = false);
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !isLastPage &&
        !isLoadingMore) {
      loadMoreArticles();
    }
  }

  void filteringArticles(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        if (query.isEmpty &&
            _selectedFromDate == null &&
            _selectedToDate == null) {
          filterArticles = List.from(allArticles);
        } else {
          final lowerQuery = query.toLowerCase();
          filterArticles = allArticles.where((article) {
            // Text search
            final matchesText =
                article.title.toLowerCase().contains(lowerQuery) ||
                    article.description.toLowerCase().contains(lowerQuery);

            // Date filter
            bool matchesDate = true;
            if (_selectedFromDate != null && article.publishedAt != null) {
              matchesDate = article.publishedAt!.isAfter(_selectedFromDate!) ||
                  article.publishedAt!.isAtSameMomentAs(_selectedFromDate!);
            }
            if (_selectedToDate != null && article.publishedAt != null) {
              matchesDate = matchesDate &&
                  (article.publishedAt!.isBefore(_selectedToDate!) ||
                      article.publishedAt!.isAtSameMomentAs(_selectedToDate!));
            }

            return matchesText && matchesDate;
          }).toList();
        }
      });
    });
  }

  Future<void> _selectFromDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedFromDate) {
      setState(() {
        _selectedFromDate = picked;
        filteringArticles(_searchController.text);
      });
    }
  }

  Future<void> _selectToDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedToDate ?? DateTime.now(),
      firstDate: _selectedFromDate ?? DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedToDate) {
      setState(() {
        _selectedToDate = picked;
        filteringArticles(_searchController.text);
      });
    }
  }

  void _clearDateFilters() {
    setState(() {
      _selectedFromDate = null;
      _selectedToDate = null;
      filteringArticles(_searchController.text);
    });
  }

  void _markArticleAsLoaded(String articleUrl) {
    _loadedArticles.add(articleUrl);
  }

  bool _isArticleLoaded(String articleUrl) {
    return _loadedArticles.contains(articleUrl);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Gap(20),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text('News', style: textTheme.headlineLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            onChanged: (val) {
              filteringArticles(val);
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search news...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white),
                      onPressed: () {
                        _searchController.clear();
                        filteringArticles('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        // Date filter row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectFromDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedFromDate != null
                              ? _dateFormat.format(_selectedFromDate!)
                              : 'From date',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () => _selectToDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _selectedToDate != null
                              ? _dateFormat.format(_selectedToDate!)
                              : 'To date',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedFromDate != null || _selectedToDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearDateFilters,
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<void>(
            future: futureInitialLoad,
            builder: (context, snapshot) {
              if (loadError) {
                return _buildErrorWidget();
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CustomLoader());
              } else if (snapshot.hasError) {
                return const Center(
                  child: Text(
                    'Error loading news',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              } else if (filterArticles.isEmpty) {
                return const Center(
                  child: Text(
                    'No news available',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                itemCount: filterArticles.length + (isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == filterArticles.length) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Center(child: CustomLoader()),
                    );
                  }

                  final article = filterArticles[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: NewsArticleTile(
                      key: ValueKey(article.url),
                      article: article,
                      isAlreadyLoaded: _isArticleLoaded(article.url),
                      onLoadComplete: () => _markArticleAsLoaded(article.url),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load news',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: fetchInitialArticles,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class NewsArticleTile extends StatefulWidget {
  final Article article;
  final bool isAlreadyLoaded;
  final VoidCallback onLoadComplete;

  const NewsArticleTile({
    Key? key,
    required this.article,
    required this.isAlreadyLoaded,
    required this.onLoadComplete,
  }) : super(key: key);

  @override
  State<NewsArticleTile> createState() => _NewsArticleTileState();
}

class _NewsArticleTileState extends State<NewsArticleTile> {
  late bool skeletonLoading;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  void initState() {
    super.initState();
    skeletonLoading = !widget.isAlreadyLoaded;

    if (!widget.isAlreadyLoaded) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() {
          skeletonLoading = false;
        });
        widget.onLoadComplete();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Skeletonizer(
      enabled: skeletonLoading,
      child: LargeListTile(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[200],
        leading: const Icon(Icons.newspaper),
        title: Text(widget.article.title, style: textTheme.bodyLarge),
        subtitle: Text(widget.article.description, style: textTheme.bodySmall),
        bottom: widget.article.publishedAt != null
            ? Text(
                _dateFormat.format(widget.article.publishedAt!),
                style: textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              )
            : null, // Don't show anything if publishedAt is null
        onTap: () {
          showDialog(
            context: context,
            builder: (_) => FullArticleWebView(url: widget.article.url),
          );
        },
      ),
    );
  }
}