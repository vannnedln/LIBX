import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
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
      final response = await _supabase.from('borrowed_books').select('''
            id, 
            book_id,
            borrow_date, 
            due_date, 
            status,
            books:book_id (
              title, 
              author,
              image_url
            )
          ''').eq('user_id', userId).eq('status', 'borrowed').order('due_date');

      // Get return requests to check which books have pending return requests
      final returnRequests = await _supabase
          .from('return_requests')
          .select('borrow_id, status')
          .eq('user_id', userId)
          .eq('status', 'pending');

      // Create a set of borrow IDs with pending return requests
      final pendingReturnBorrowIds = Set<int>.from(
          returnRequests.map((request) => request['borrow_id'] as int));

      // Convert response to BorrowedBook objects
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
      if (query.isEmpty) {
        _filteredBooks = _borrowedBooks;
      } else {
        _filteredBooks = _borrowedBooks
            .where((book) =>
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.author.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
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

      // Create a return request instead of updating the borrowed_books table
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
            bottom: 45, // Space for the return button
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
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Borrowed Books',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep track of your borrowed books',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search Bar
                  Container(
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
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: secondary),
                    )
                  : _filteredBooks.isEmpty
                      ? Center(
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
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    _filterBooks('');
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: secondary,
                                  ),
                                  child: const Text('Clear Search'),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadBorrowedBooks,
                          color: secondary,
                          child: GridView.builder(
                            padding: const EdgeInsets.all(20),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.7,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: _filteredBooks.length,
                            itemBuilder: (context, index) {
                              return _buildBookCard(_filteredBooks[index]);
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
