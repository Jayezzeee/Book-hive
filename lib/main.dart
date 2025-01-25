import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(BookFinderApp());
}

class BookFinderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: BookSearchScreen(),
    );
  }
}

class BookSearchScreen extends StatefulWidget {
  @override
  _BookSearchScreenState createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _searchHistory = [];
  final List<dynamic> _favorites = [];
  List<dynamic> _books = [];
  bool _isLoading = false;
  String _errorMessage = '';
  Timer? _debounce;

  Future<void> _searchBooks(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('https://www.googleapis.com/books/v1/volumes?q=$query&maxResults=20'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _books = data['items'] ?? [];
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to fetch data. Please try again later.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(Duration(milliseconds: 500), () {
      if (!_searchHistory.contains(query)) {
        setState(() {
          _searchHistory.add(query);
        });
      }
      _searchBooks(query);
    });
  }

  void _clearSearchHistory() {
    setState(() {
      _searchHistory.clear();
    });
  }

  void _addToFavorites(dynamic book) {
    if (!_favorites.contains(book)) {
      setState(() {
        _favorites.add(book);
      });
    }
  }

  void _viewFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FavoritesScreen(favorites: _favorites),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Book Finder'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.light
                    ? Colors.white
                    : Colors.grey[800],
                labelText: 'Search for books',
                hintText: 'Enter book title or author',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: Icon(Icons.search),
              ),
            ),
            SizedBox(height: 16),

            // Search history
            if (_searchHistory.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search History:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: _searchHistory.map((query) {
                      return ActionChip(
                        label: Text(query),
                        onPressed: () {
                          _searchController.text = query;
                          _searchBooks(query);
                        },
                      );
                    }).toList(),
                  ),
                  TextButton(
                    onPressed: _clearSearchHistory,
                    child: Text('Clear History', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            SizedBox(height: 16),

            // View favorites button
            ElevatedButton.icon(
              onPressed: _viewFavorites,
              icon: Icon(Icons.favorite, color: Colors.white),
              label: Text('View Favorites'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
            ),
            SizedBox(height: 16),

            // Book list or loading/error indicator
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(fontSize: 18, color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _books.isEmpty
                          ? Center(
                              child: Text(
                                'No results found.',
                                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _books.length,
                              itemBuilder: (context, index) {
                                final book = _books[index];
                                final volumeInfo = book['volumeInfo'];
                                final imageLinks = volumeInfo['imageLinks'];
                                final imageUrl = imageLinks != null ? imageLinks['thumbnail'] : null;

                                // Debug print to check URL
                                print('Image URL: $imageUrl');

                                return Card(
                                  margin: EdgeInsets.symmetric(vertical: 8),
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    contentPadding: EdgeInsets.all(8),
                                    leading: imageUrl != null && imageUrl.isNotEmpty
                                        ? Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) {
                                                return child;
                                              } else {
                                                return Center(
                                                  child: CircularProgressIndicator(
                                                    value: loadingProgress.expectedTotalBytes != null
                                                        ? loadingProgress.cumulativeBytesLoaded /
                                                            (loadingProgress.expectedTotalBytes ?? 1)
                                                        : null,
                                                  ),
                                                );
                                              }
                                            },
                                            errorBuilder: (context, error, stackTrace) {
                                              // If image fails to load, show a placeholder icon
                                              return Icon(Icons.broken_image, size: 40);
                                            },
                                          )
                                        : Icon(Icons.book, size: 40),
                                    title: Text(
                                      volumeInfo['title'] ?? 'No Title',
                                      style: TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text(
                                      volumeInfo['authors']?.join(', ') ?? 'Unknown Author',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.favorite,
                                        color: _favorites.contains(book)
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      onPressed: () => _addToFavorites(book),
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookDetailScreen(
                                            book: book,
                                            onLike: _addToFavorites,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final dynamic book;
  final void Function(dynamic) onLike;

  BookDetailScreen({required this.book, required this.onLike});

  @override
  Widget build(BuildContext context) {
    final volumeInfo = book['volumeInfo'];
    final imageLinks = volumeInfo['imageLinks'];
    final description = volumeInfo['description'] ?? 'No description available';
    final title = volumeInfo['title'] ?? 'No Title';
    final authors = volumeInfo['authors']?.join(', ') ?? 'Unknown Author';

    return Scaffold(
      appBar: AppBar(
        title: Text('Book Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Book Cover Image
            imageLinks != null && imageLinks['thumbnail'] != null
                ? Image.network(
                    imageLinks['thumbnail'],
                    fit: BoxFit.cover,
                    height: 250,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      } else {
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        );
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.broken_image, size: 100);
                    },
                  )
                : Icon(Icons.book, size: 100),
            SizedBox(height: 16),
            // Book Title
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            // Book Authors
            Text(
              'By $authors',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16),
            // Book Description
            Text(
              description,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            // Like Button
            ElevatedButton.icon(
              onPressed: () => onLike(book),
              icon: Icon(Icons.favorite, color: Colors.white),
              label: Text('Like'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoritesScreen extends StatelessWidget {
  final List<dynamic> favorites;

  FavoritesScreen({required this.favorites});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Text(
                'No favorites yet.',
                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic),
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final book = favorites[index];
                final volumeInfo = book['volumeInfo'];
                final imageLinks = volumeInfo['imageLinks'];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(8),
                    leading: imageLinks != null && imageLinks['thumbnail'] != null
                        ? Image.network(
                            imageLinks['thumbnail'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.broken_image, size: 40);
                            },
                          )
                        : Icon(Icons.book, size: 40),
                    title: Text(
                      volumeInfo['title'] ?? 'No Title',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      volumeInfo['authors']?.join(', ') ?? 'Unknown Author',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
