import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

class BorrowedBooksPage extends StatefulWidget {
  const BorrowedBooksPage({Key? key}) : super(key: key);

  @override
  State<BorrowedBooksPage> createState() => _BorrowedBooksPageState();
}

class _BorrowedBooksPageState extends State<BorrowedBooksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _borrowedBooks = [];
  String _selectedStatus = 'borrowed';

  @override
  void initState() {
    super.initState();
    _loadBorrowedBooks();
  }

  Future<void> _loadBorrowedBooks() async {
    try {
      final response =
          await Supabase.instance.client.from('borrowed_books').select('''
            *,
            profiles (
              full_name,
              avatar_url
            ),
            books (
              id,
              title,
              author,
              genre,
              year
            )
          ''').eq('status', _selectedStatus).order('due_date');

      if (!mounted) return;
      setState(() {
        _borrowedBooks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error loading borrowed books: $e');
    }
  }

  Future<void> _markAsReturned(int bookId, String userId) async {
    try {
      await Supabase.instance.client
          .from('borrowed_books')
          .update({
            'status': 'returned',
            'return_date': DateTime.now().toIso8601String(),
          })
          .eq('book_id', bookId)
          .eq('user_id', userId)
          .eq('status', 'borrowed');

      _loadBorrowedBooks();
    } catch (e) {
      print('Error marking book as returned: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Borrowed Books',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: secondary,
        elevation: 4,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5),
            child: TextField(
              onChanged: (query) {
                setState(() {
                  _borrowedBooks = _borrowedBooks
                      .where((book) =>
                          book['books']['title']
                              .toString()
                              .toLowerCase()
                              .contains(query.toLowerCase()) ||
                          book['books']['author']
                              .toString()
                              .toLowerCase()
                              .contains(query.toLowerCase()) ||
                          book['status']
                              .toString()
                              .toLowerCase()
                              .contains(query.toLowerCase()) ||
                          book['profiles']['full_name']
                              .toString()
                              .toLowerCase()
                              .contains(query.toLowerCase()))
                      .toList();
                });
              },
              cursorColor: primary,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: secondary,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterButton('borrowed', 'Current'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton('returned', 'Returned'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterButton('overdue', 'Overdue'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Skeletonizer(
              enabled: _isLoading,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _isLoading ? 3 : _borrowedBooks.length,
                itemBuilder: (context, index) {
                  if (_isLoading) {
                    return _buildBorrowedBookCard(null);
                  }
                  final book = _borrowedBooks[index];
                  return _buildBorrowedBookCard(book);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String status, String label) {
    final isSelected = _selectedStatus == status;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _selectedStatus = status;
            _isLoading = true;
          });
          _loadBorrowedBooks();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? secondary : Colors.grey[100],
          foregroundColor: isSelected ? Colors.white : Colors.grey[800],
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? secondary : Colors.grey[300]!,
              width: 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildBorrowedBookCard(Map<String, dynamic>? book) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Dismissible(
        key: book != null ? Key(book['id'].toString()) : UniqueKey(),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          if (book != null && _selectedStatus == 'borrowed') {
            return await showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Return'),
                content: const Text('Mark this book as returned?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Return'),
                  ),
                ],
              ),
            );
          }
          return false;
        },
        onDismissed: (direction) {
          if (book != null) {
            _markAsReturned(book['book_id'], book['user_id']);
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.green,
          child: const Icon(Icons.check, color: Colors.white),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // User Avatar and Book Details content
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[200],
                backgroundImage:
                    book != null && book['profiles']['avatar_url'] != null
                        ? NetworkImage(book['profiles']['avatar_url'])
                        : null,
                child: book == null || book['profiles']['avatar_url'] == null
                    ? const Icon(Icons.person, size: 35, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book?['books']['title'] ?? 'Book Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${book?['books']['author'] ?? 'Unknown Author'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Borrowed by: ${book?['profiles']['full_name'] ?? 'User Name'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        book != null
                            ? _getDaysLeft(book['due_date'])
                            : '7 days left',
                        style: TextStyle(
                          fontSize: 12,
                          color: secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDaysLeft(String dueDate) {
    final due = DateTime.parse(dueDate);
    final now = DateTime.now();
    final difference = due.difference(now);
    final days = difference.inDays;

    if (days < 0) {
      return '${days.abs()} days overdue';
    } else if (days == 0) {
      return 'Due today';
    } else if (days == 1) {
      return '1 day left';
    } else {
      return '$days days left';
    }
  }
}
