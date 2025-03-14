import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/user/borrowed_books_page.dart';
import 'package:libx_final/pages/auth/user/book_details_page.dart';
import 'package:libx_final/pages/auth/user/browse_books_page.dart';
import 'package:libx_final/pages/auth/user/user_root_app.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart'; // Add this import

// Change to StatefulWidget
class UserHomepage extends StatefulWidget {
  final String firstName;
  const UserHomepage({super.key, required this.firstName});

  @override
  State<UserHomepage> createState() => _UserHomepageState();
}

class Book {
  final int id;
  final String title;
  final String author;
  final int quantity;
  final String genre;
  final String description;
  final String coverUrl;
  final DateTime? createdAt;
  final int? year; // Add year property

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.quantity,
    required this.genre,
    required this.description,
    required this.coverUrl,
    this.createdAt,
    this.year, // Add year parameter
  });
}

class _UserHomepageState extends State<UserHomepage> {
  final _supabase = Supabase.instance.client;
  List<Book> availableBooks = [];
  List<Map<String, dynamic>> borrowedBooks = [];
  bool isLoading = true;
  String? selectedCategory;
  String? _userAvatarUrl;
  int borrowedCount = 0;
  int returnedCount = 0;

  final List<String> categories = [
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'fiction':
        return Icons.auto_stories_rounded;
      case 'non-fiction':
        return Icons.menu_book_rounded;
      case 'science fiction':
        return Icons.rocket_launch_rounded;
      case 'fantasy':
        return Icons.auto_fix_high_rounded;
      case 'mystery':
        return Icons.search_rounded;
      case 'thriller':
        return Icons.psychology_rounded;
      case 'romance':
        return Icons.favorite_rounded;
      case 'horror':
        return Icons.dark_mode_rounded;
      case 'history':
        return Icons.history_edu_rounded;
      case 'biography':
        return Icons.person_rounded;
      case 'self-help':
        return Icons.psychology_alt_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'technology':
        return Icons.computer_rounded;
      case 'science':
        return Icons.science_rounded;
      case 'poetry':
        return Icons.format_quote_rounded;
      case 'drama':
        return Icons.theater_comedy_rounded;
      case 'children':
        return Icons.child_care_rounded;
      case 'young adult':
        return Icons.groups_rounded;
      case 'educational':
        return Icons.school_rounded;
      case 'reference':
        return Icons.library_books_rounded;
      default:
        return Icons.book_rounded;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchBooks();
    fetchUserProfile();
    fetchBorrowedBooks();
    fetchBorrowingStats();
  }

  void _onCategoryTap(String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrowseBooksPage(
          initialCategory: category,
          showAvailableOnly: true, // Add this parameter
        ),
      ),
    );
  }

  // Add this method
  Future<void> fetchBorrowingStats() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final borrowedResponse = await _supabase
          .from('borrowed_books')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'borrowed');

      final returnedResponse = await _supabase
          .from('borrowed_books')
          .select('id')
          .eq('user_id', userId)
          .eq('status', 'returned');

      if (mounted) {
        setState(() {
          borrowedCount = borrowedResponse.length;
          returnedCount = returnedResponse.length;
        });
      }
    } catch (error) {
      print('Error fetching borrowing stats: $error');
    }
  }

  // Add this method
  Future<void> fetchBorrowedBooks() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('borrowed_books')
          .select('*, books(*)')
          .eq('user_id', userId)
          .eq('status', 'borrowed')
          .order('due_date', ascending: true)
          .limit(4);

      if (mounted && response != null) {
        setState(() {
          borrowedBooks = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (error) {
      print('Error fetching borrowed books: $error');
    }
  }

  // Add this method
  Future<void> fetchUserProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', userId)
          .single();

      if (mounted && response != null) {
        setState(() {
          _userAvatarUrl = response['avatar_url'];
        });
      }
    } catch (error) {
      print('Error fetching user profile: $error');
    }
  }

  Future<void> fetchBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .gt('quantity', 0)
          .order('created_at', ascending: false);

      if (response != null) {
        setState(() {
          availableBooks = (response as List<dynamic>)
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
                        ? DateTime.parse(book['created_at'])
                        : null,
                    year: () {
                      var yearValue = book['year'];
                      if (yearValue == null) return null;
                      try {
                        return int.parse(yearValue.toString());
                      } catch (e) {
                        return null;
                      }
                    }(),
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

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([
      fetchBooks(),
      fetchBorrowedBooks(),
      fetchBorrowingStats(),
    ]);
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: RefreshIndicator(
          color: primary,
          backgroundColor: Colors.white,
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Skeletonizer(
              enabled: isLoading,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Skeletonizer(
                    enabled: isLoading,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: secondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1),
                            ),
                            child: CircleAvatar(
                              radius: 26,
                              backgroundColor: Colors.grey[200],
                              backgroundImage: _userAvatarUrl != null
                                  ? NetworkImage(_userAvatarUrl!)
                                  : null,
                              child: _userAvatarUrl == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 30,
                                      color: secondary,
                                    )
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back,',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.firstName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Search Bar
                  Skeletonizer(
                    enabled: isLoading,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
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
                  ),

                  // Borrowing Statistics
                  Skeletonizer(
                    enabled: isLoading,
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  borrowedCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: primary,
                                  ),
                                ),
                                const Text(
                                  'Currently\nBorrowed',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  returnedCount.toString(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: secondary,
                                  ),
                                ),
                                const Text(
                                  'Total\nReturned',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),

                  // Top Available Books Section
                  Skeletonizer(
                    enabled: isLoading,
                    child: _buildSectionHeader(
                      'Top Available for you!',
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BrowseBooksPage(
                            initialCategory: 'All',
                            showAvailableOnly: true, // Add this parameter
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      // In the build method, replace the ListView.builder for available books

                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableBooks.length,
                        itemBuilder: (context, index) {
                          final book = availableBooks[index];
                          return GestureDetector(
                            // Fix: Return the GestureDetector
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      BookDetailsPage(book: book),
                                ),
                              );
                            },
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        book.coverUrl,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.book,
                                              size: 40,
                                              color: Colors.grey,
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
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Popular Genres
                  Skeletonizer(
                    enabled: isLoading,
                    child: _buildSectionHeader('Pick from Popular Genres'),
                  ),
                  const SizedBox(height: 16),
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          final color = categoryColor[category] ?? Colors.grey;
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildGenreCard(
                              category,
                              _getCategoryIcon(category),
                              color,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recently Borrowed Books
                  Skeletonizer(
                    enabled: isLoading,
                    child: _buildSectionHeader(
                      'Recently Borrowed Books',
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BorrowedBooksPage(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      height: 160,
                      child: borrowedBooks.isEmpty
                          ? Center(
                              child: Text(
                                'No borrowed books',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: borrowedBooks.length,
                              itemBuilder: (context, index) {
                                final borrowedBook = borrowedBooks[index];
                                final book = borrowedBook['books'];
                                final dueDate =
                                    DateTime.parse(borrowedBook['due_date']);
                                final daysLeft =
                                    dueDate.difference(DateTime.now()).inDays;

                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BorrowedBooksPage(),
                                    ),
                                  ),
                                  child: Container(
                                    width: 120,
                                    margin: const EdgeInsets.only(right: 16),
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
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            book['image_url'] ??
                                                'https://via.placeholder.com/150',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.book,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          left: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 8,
                                              horizontal: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: daysLeft <= 1
                                                  ? Colors.red.withOpacity(0.8)
                                                  : primary.withOpacity(0.8),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                bottom: Radius.circular(12),
                                              ),
                                            ),
                                            child: Text(
                                              '$daysLeft Days Left',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onViewAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primary,
          ),
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            child: Text(
              'View All',
              style: TextStyle(color: secondary),
            ),
          ),
      ],
    );
  }

  Widget _buildGenreCard(String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onCategoryTap(title), // Update this line
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 28, color: color),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
