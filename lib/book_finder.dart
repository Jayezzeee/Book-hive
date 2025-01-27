import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class BookFinderApp extends StatelessWidget {

  final String username;

  // Add a constructor to accept the username
  BookFinderApp({required this.username});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color.fromARGB(255, 255, 230, 0), // Set background color to yellow
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.yellow, // Maintain consistency in dark theme
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

  void _removeFromFavorites(dynamic book) {
  setState(() {
    _favorites.remove(book);
  });
}

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
                fillColor: const Color.fromARGB(255, 61, 50, 50),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: const Color.fromARGB(255, 13, 0, 0)),
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
                  SizedBox(height: 16),
                  TextButton(
                    onPressed: _clearSearchHistory,
                    child: Text('Clear History', style: TextStyle(color: const Color.fromARGB(255, 228, 129, 203))),
                    style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 121, 1, 11),
              ),
                  ),
                ],
              ),
            SizedBox(height: 16),

            // View favorites button
            ElevatedButton.icon(
              onPressed: _viewFavorites,
              icon: Icon(Icons.favorite, color: const Color.fromARGB(255, 231, 8, 8)),
              label: Text('View Favorites',style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
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
                                style: TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: const Color.fromARGB(255, 11, 1, 0)),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _books.length,
                              itemBuilder: (context, index) {
                                final book = _books[index];
                                final volumeInfo = book['volumeInfo'];
                                final imageLinks = volumeInfo['imageLinks'];
                                final imageUrl = imageLinks != null ? imageLinks['thumbnail'] : null;

                                // Generate the image URL for each book
                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                  print(
                                      'Image URL for Book ${volumeInfo['title']}: $imageUrl');
                                }

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
                                      onPressed: () {
                                        if (_favorites.contains(book)) {
                                          _removeFromFavorites(book);
                                        } else {
                                          _addToFavorites(book);
                                        }
                                      },
                                    ),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BookDetailScreen(
                                            book: book,
                                            onLike: _addToFavorites,
                                            onUnlike: _removeFromFavorites,
                                            favorites: _favorites,
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

class BookDetailScreen extends StatefulWidget {
  final dynamic book;
  final void Function(dynamic) onLike;
  final void Function(dynamic) onUnlike;
  final List<dynamic> favorites;

  BookDetailScreen({required this.book, required this.onLike, required this.onUnlike, required this.favorites});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final volumeInfo = widget.book['volumeInfo'];
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
            Text(
              title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 70, 2, 166)),
            ),
            SizedBox(height: 8),
            Text(
              'By $authors',
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            SizedBox(height: 16),
            Text(
              description,
              style: TextStyle(fontSize: 16,color: const Color.fromARGB(255, 0, 0, 0)),
            ),
            SizedBox(height: 16),
            // Favorite button with color change
            ElevatedButton.icon(
              onPressed: () {
                setState((){
                  if (widget.favorites.contains(widget.book)) {
                  widget.onUnlike(widget.book);
                } else {
                  widget.onLike(widget.book);
                }
              });
              },
              icon: Icon(
                Icons.favorite,
                color: widget.favorites.contains(widget.book)
                ? const Color.fromARGB(255, 255, 0, 0)
                : const Color.fromARGB(255, 255, 255, 255), // Color for the icon when liked
              ),
              label: Text('Like'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 88, 88, 88)),
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