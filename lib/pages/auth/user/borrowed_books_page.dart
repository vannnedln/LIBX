import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BorrowedBook {
  final int id;
  final int bookId;
  final String title;
  final String author;
  final String coverUrl;
  final DateTime borrowDate;
  final DateTime dueDate;
  final String status;
  final bool hasReturnRequest;
  final String genre; // Add this field

  BorrowedBook({
    required this.id,
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    required this.borrowDate,
    required this.dueDate,
    required this.status,
    this.hasReturnRequest = false,
    required this.genre, // Add this parameter
  });
}

class BorrowedBooksPage extends StatefulWidget {
  const BorrowedBooksPage({super.key});

  @override
  State<BorrowedBooksPage> createState() => _BorrowedBooksPageState();
}

class _BorrowedBooksPageState extends State<BorrowedBooksPage> {
  final _supabase = Supabase.instance.client;
  List<BorrowedBook> _borrowedBooks = [];
  List<BorrowedBook> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';

  // Add these new properties
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
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _supabase.auth.currentUser!.id;

      // Get borrowed books
      // Update the select query to include genre
      final response = await _supabase.from('borrowed_books').select('''
            id, 
            book_id,
            borrow_date, 
            due_date, 
            status,
            books:book_id (
              title, 
              author,
              image_url,
              genre
            )
          ''').eq('user_id', userId).eq('status', 'borrowed').order('due_date');

      final returnRequests = await _supabase
          .from('return_requests')
          .select('borrow_id, status')
          .eq('user_id', userId)
          .eq('status', 'pending');

      final pendingReturnBorrowIds = Set<int>.from(
          returnRequests.map((request) => request['borrow_id'] as int));

      final List<BorrowedBook> books = [];
      for (var item in response) {
        final book = item['books'];
        books.add(
          BorrowedBook(
            id: item['id'],
            bookId: item['book_id'],
            title: book['title'],
            author: book['author'],
            coverUrl: book['image_url'],
            borrowDate: DateTime.parse(item['borrow_date']),
            dueDate: DateTime.parse(item['due_date']),
            status: item['status'],
            hasReturnRequest: pendingReturnBorrowIds.contains(item['id']),
            genre: book['genre'] ?? 'Unknown',
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _borrowedBooks = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      print('Error loading borrowed books: $e');
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      _filteredBooks = _borrowedBooks.where((book) {
        final matchesSearch = query.isEmpty ||
            book.title.toLowerCase().contains(query.toLowerCase()) ||
            book.author.toLowerCase().contains(query.toLowerCase());

        final matchesCategory = selectedCategory == null ||
            selectedCategory == 'All' ||
            book.genre == selectedCategory;

        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  String _getDaysRemaining(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return 'Overdue by ${-difference} days';
    } else if (difference == 0) {
      return 'Due today';
    } else if (difference == 1) {
      return 'Due tomorrow';
    } else {
      return 'Due in $difference days';
    }
  }

  Future<void> _returnBook(int borrowId, int bookId) async {
    try {
      // Show confirmation dialog
      final shouldRequest = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Request Book Return',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: const Text('Do you want to request to return this book?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: primary),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondary,
              ),
              child: const Text(
                'Return',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );

      if (shouldRequest != true) return;

      await _supabase.from('return_requests').insert({
        'borrow_id': borrowId,
        'user_id': _supabase.auth.currentUser!.id,
        'book_id': bookId,
        'request_date': DateTime.now().toIso8601String(),
        'status': 'pending'
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Return request submitted successfully. Please wait for admin approval.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Refresh the list
      _loadBorrowedBooks();
    } catch (e) {
      print('Error requesting return: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBookCard(BorrowedBook book) {
    final daysLeft = book.dueDate.difference(DateTime.now()).inDays;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Book Cover Image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Image.network(
                book.coverUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.book_rounded,
                      size: 50,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          ),
          // Days Left Indicator
          Positioned(
            bottom: 45,
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
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Text(
                '$daysLeft Days Left',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          // Return Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: TextButton(
                onPressed: book.hasReturnRequest
                    ? null
                    : () => _returnBook(book.id, book.bookId),
                style: TextButton.styleFrom(
                  backgroundColor:
                      book.hasReturnRequest ? Colors.grey : secondary,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(16),
                    ),
                  ),
                ),
                child: Text(
                  book.hasReturnRequest ? 'Requested' : 'Return',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: secondary,
        centerTitle: true,
        title: Text(
          "Borrowed Books",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadBorrowedBooks,
        color: primary,
        backgroundColor: Colors.white,
        child: Skeletonizer(
          enabled: _isLoading,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 0,
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: TextField(
                          enabled: !_isLoading,
                          cursorColor: primary,
                          decoration: InputDecoration(
                            hintText: 'Search borrowed books...',
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            prefixIcon: Icon(Icons.search, color: secondary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: _filterBooks,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Category Filter
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _isLoading ? 6 : categories.length,
                          itemBuilder: (context, index) {
                            if (_isLoading) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 15),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      width: 60,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            IconData categoryIcon =
                                _getCategoryIcon(categories[index]);
                            Color categoryColors =
                                categoryColor[categories[index]] ?? Colors.blue;
                            return _buildCategoryItem(
                                index, categoryIcon, categoryColors);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _isLoading
                        ? 6
                        : (_filteredBooks.isEmpty ? 1 : _filteredBooks.length),
                    itemBuilder: (context, index) {
                      if (_isLoading) {
                        return _buildBookCard(
                          BorrowedBook(
                            id: index,
                            bookId: index,
                            title: 'Loading...',
                            author: 'Loading...',
                            coverUrl: '',
                            borrowDate: DateTime.now(),
                            dueDate: DateTime.now().add(Duration(days: 7)),
                            status: 'borrowed',
                            genre: 'Loading...',
                          ),
                        );
                      }

                      if (_filteredBooks.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.book_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No books match your search'
                                    : 'You have no borrowed books',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return _buildBookCard(_filteredBooks[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryItem(
      int index, IconData categoryIcon, Color categoryColors) {
    return Padding(
      padding: const EdgeInsets.only(right: 15),
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedCategory = categories[index];
            _filterBooks(_searchQuery);
          });
        },
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: selectedCategory == categories[index]
                    ? categoryColors
                    : categoryColors.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(
                categoryIcon,
                size: 30,
                color: selectedCategory == categories[index]
                    ? Colors.white
                    : categoryColors,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              categories[index],
              style: TextStyle(
                fontSize: 12,
                color: selectedCategory == categories[index]
                    ? categoryColors
                    : Colors.grey[600],
                fontWeight: selectedCategory == categories[index]
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
      return Icons.psychology_rounded;
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
      return Icons.group_rounded;
    case 'Educational':
      return Icons.school_rounded;
    case 'Reference':
      return Icons.library_books_rounded;
    default:
      return Icons.book_rounded;
  }
}
