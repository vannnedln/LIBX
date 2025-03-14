import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:libx_final/pages/auth/user/book_details_page.dart';
import 'package:libx_final/pages/auth/user/user_homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BrowseBooksPage extends StatefulWidget {
  final String? initialCategory;
  final bool showAvailableOnly;
  const BrowseBooksPage({
    super.key,
    this.initialCategory,
    this.showAvailableOnly = false,
  });

  @override
  State<BrowseBooksPage> createState() => _BrowseBooksPageState();
}

class _BrowseBooksPageState extends State<BrowseBooksPage> {
  final _supabase = Supabase.instance.client;
  List<Book> books = [];
  bool isLoading = true;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  String? selectedCategory;

  final List<String> categories = [
    'All',
    'Fiction',
    'Non-Fiction',
    'Science Fiction',
    'Fantasy',
    'Mystery',
    'Thriller',
    'Romance',
    'Horror',
    'History',
    'Biography',
    'Self-Help',
    'Business',
    'Technology',
    'Science',
    'Poetry',
    'Drama',
    'Children',
    'Young Adult',
    'Educational',
    'Reference',
  ];

  final Map<String, Color> categoryColor = {
    'All': Colors.blue,
    'Fiction': Colors.purple,
    'Non-Fiction': Colors.green,
    'Science Fiction': Colors.orange,
    'Fantasy': Colors.red,
    'Mystery': Colors.indigo,
    'Thriller': Colors.deepOrange,
    'Romance': Colors.pink,
    'Horror': Colors.grey[850]!,
    'History': Colors.brown,
    'Biography': Colors.teal,
    'Self-Help': Colors.cyan,
    'Business': Colors.amber,
    'Technology': Colors.lightBlue,
    'Science': Colors.deepPurple,
    'Poetry': Colors.purple[300]!,
    'Drama': Colors.orange[800]!,
    'Children': Colors.yellow[700]!,
    'Young Adult': Colors.lightGreen,
    'Educational': Colors.indigoAccent,
    'Reference': Colors.blueGrey,
  };

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.initialCategory; // Set initial category
    fetchBooks();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchBooks() async {
    try {
      var query = _supabase.from('books').select();

      // Only filter by quantity if showAvailableOnly is true
      if (widget.showAvailableOnly) {
        query = query.gt('quantity', 0);
      }
      // Otherwise, show all books regardless of quantity

      // Apply category filter if selected
      if (selectedCategory != null && selectedCategory != 'All') {
        query = query.eq('genre', selectedCategory as Object);
      }

      final response = await query.order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          books = (response as List<dynamic>)
              .map((book) => Book(
                    id: book['id'],
                    title: book['title'],
                    author: book['author'],
                    quantity: book['quantity'],
                    genre: book['genre'] ?? 'Unknown',
                    description:
                        book['description'] ?? 'No description available',
                    coverUrl:
                        book['image_url'] ?? 'https://via.placeholder.com/150',
                    createdAt: book['created_at'] != null
                        ? DateTime.parse(book['created_at'].toString())
                        : null,
                    year: book['year'] != null
                        ? int.tryParse(book['year'].toString())
                        : null,
                  ))
              .toList();
          isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching books: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Book> getFilteredBooks() {
    return books.where((book) {
      final matchesSearch =
          book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              book.author.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = selectedCategory == null ||
          selectedCategory == 'All' ||
          book.genre == selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.apps_rounded;
      case 'Fiction':
        return Icons.auto_stories_rounded;
      case 'Non-Fiction':
        return Icons.menu_book_rounded;
      case 'Science Fiction':
        return Icons.rocket_launch_rounded;
      case 'Fantasy':
        return Icons.auto_fix_high_rounded;
      case 'Mystery':
        return Icons.search_rounded;
      case 'Thriller':
        return Icons.psychology_rounded;
      case 'Romance':
        return Icons.favorite_rounded;
      case 'Horror':
        return Icons.dark_mode_rounded;
      case 'History':
        return Icons.history_edu_rounded;
      case 'Biography':
        return Icons.person_rounded;
      case 'Self-Help':
        return Icons.lightbulb_rounded;
      case 'Business':
        return Icons.business_center_rounded;
      case 'Technology':
        return Icons.computer_rounded;
      case 'Science':
        return Icons.science_rounded;
      case 'Poetry':
        return Icons.format_quote_rounded;
      case 'Drama':
        return Icons.theater_comedy_rounded;
      case 'Children':
        return Icons.child_care_rounded;
      case 'Young Adult':
        return Icons.groups_rounded;
      case 'Educational':
        return Icons.school_rounded;
      case 'Reference':
        return Icons.library_books_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = getFilteredBooks();
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: secondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Browse Books',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search bar container
                  Container(
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 0,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      cursorColor: primary,
                      controller: _searchController,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        hintText: 'Search books...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: secondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Categories with Skeletonizer
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final categoryColors =
                              categoryColor[category] ?? Colors.blue;
                          final isSelected = selectedCategory == category;

                          return Padding(
                            padding: const EdgeInsets.only(right: 15),
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                              child: Column(
                                children: [
                                  Container(
                                    width: 65,
                                    height: 65,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? categoryColors.withOpacity(0.2)
                                          : categoryColors.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      color: categoryColors,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    category,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isSelected
                                          ? categoryColors
                                          : Colors.grey[600],
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: secondary,
                onRefresh: () async {
                  setState(() {
                    isLoading = true;
                  });
                  await fetchBooks();
                },
                child: isLoading
                    ? Skeletonizer(
                        enabled: true,
                        child: GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.7,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: 6, // Show 6 skeleton items while loading
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            );
                          },
                        ),
                      )
                    : filteredBooks.isEmpty
                        ? ListView(
                            children: const [
                              const SizedBox(
                                height: 150,
                              ),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No books found',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : GridView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredBooks.length,
                            itemBuilder: (context, index) {
                              final book = filteredBooks[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => BookDetailsPage(
                                      book: book,
                                    ),
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: NetworkImage(book.coverUrl),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) =>
                                              const AssetImage(
                                                  'assets/images/book_placeholder.png'),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.1),
                                            spreadRadius: 0,
                                            blurRadius: 10,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (book.quantity <= 0)
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          color: Colors.black.withOpacity(0.6),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Unavailable',
                                            style: TextStyle(
                                              color: Colors.red[50],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
