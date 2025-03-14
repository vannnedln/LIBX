import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';

// Add this extension at the top of the file after imports
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

class BorrowedBooksPage extends StatefulWidget {
  const BorrowedBooksPage({Key? key}) : super(key: key);

  @override
  State<BorrowedBooksPage> createState() => _BorrowedBooksPageState();
}

class _BorrowedBooksPageState extends State<BorrowedBooksPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _borrowedBooks = [];
  String _selectedStatus = 'pending'; // Changed default to pending
  String _requestType =
      'borrow'; // Add this to track request type (borrow or return)
  bool _showRequestTypes =
      false; // Add this to control visibility of request type filters

  @override
  void initState() {
    super.initState();
    // Set initial states
    _selectedStatus = 'pending';
    _showRequestTypes = true;
    _requestType = 'borrow';
    _loadBorrowedBooks();
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _isLoading = false;
    _borrowedBooks = [];
    super.dispose();
  }

  Future<void> _loadBorrowedBooks() async {
    if (!mounted) return;

    try {
      setState(() => _isLoading = true);

      if (_selectedStatus == 'pending' && _showRequestTypes) {
        if (_requestType == 'borrow') {
          final response =
              await Supabase.instance.client.from('borrowed_books').select('''
                *,
                books (
                  id,
                  title,
                  author,
                  genre,
                  year,
                  cover_url
                ),
                profiles:user_id (
                  full_name,
                  avatar_url
                )
              ''').eq('status', 'pending').order('due_date');

          if (!mounted) return;
          setState(() {
            _borrowedBooks = List<Map<String, dynamic>>.from(response);
            _isLoading = false;
          });
        } else {
          await _loadReturnRequests();
        }
      } else {
        final response =
            await Supabase.instance.client.from('borrowed_books').select('''
              *,
              books (
                id,
                title,
                author,
                genre,
                year,
                cover_url
              ),
              profiles:user_id (
                full_name,
                avatar_url
              )
            ''').eq('status', _selectedStatus).order('due_date');

        if (!mounted) return;
        setState(() {
          _borrowedBooks = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error loading borrowed books: $e');
    }
  }

  Future<void> _loadReturnRequests() async {
    try {
      final response =
          await Supabase.instance.client.from('return_requests').select('''
            *,
            borrowed_books!inner (
              id,
              user_id,
              book_id,
              borrow_date,
              due_date,
              status,
              books (
                id,
                title,
                author,
                genre,
                year,
                cover_url
              ),
              profiles:user_id (
                full_name,
                avatar_url
              )
            )
          ''').eq('status', 'pending').order('request_date');

      if (!mounted) return;
      setState(() {
        _borrowedBooks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error loading return requests: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading return requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add a method to load returned books from return_requests
  Future<void> _loadReturnedBooks() async {
    try {
      final response =
          await Supabase.instance.client.from('return_requests').select('''
        *,
        borrowed_books!inner (
          id,
          user_id,
          book_id,
          borrow_date,
          due_date,
          return_date,
          status,
          profiles:user_id (
            full_name,
            avatar_url
          )
        ),
        books:book_id (
          id,
          title,
          author,
          genre,
          year
        )
      ''').eq('status', 'approved').order('request_date', ascending: false);

      if (!mounted) return;
      setState(() {
        _borrowedBooks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      print('Error loading returned books: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading returned books: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildFilterButton(
                    'pending',
                    'Requests',
                    Icons.pending_actions_rounded,
                  ),
                  const SizedBox(width: 16), // Added spacing
                  _buildFilterButton(
                    'borrowed',
                    'Current',
                    Icons.book_rounded,
                  ),
                  const SizedBox(width: 16), // Added spacing
                  _buildFilterButton(
                    'returned',
                    'Returned',
                    Icons.assignment_return_rounded,
                  ),
                  const SizedBox(width: 16), // Added spacing
                  _buildFilterButton(
                    'overdue',
                    'Overdue',
                    Icons.warning_rounded,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          if (_showRequestTypes)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 0,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildRequestTypeButton('borrow', 'Borrow Requests'),
                  ),
                  const SizedBox(width: 8), // Reduced spacing
                  Expanded(
                    child: _buildRequestTypeButton('return', 'Return Requests'),
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

  Widget _buildFilterButton(String status, String label, IconData icon) {
    final isSelected = _selectedStatus == status;

    final Color statusColor = {
          'pending': Colors.orange[500],
          'borrowed': Colors.blue[500],
          'returned': Colors.green[500],
          'overdue': Colors.red[500],
        }[status] ??
        secondary;

    return SizedBox(
      width: 65, // Reduced width
      height: 65, // Reduced height
      child: ElevatedButton(
        onPressed: () {
          if (!mounted) return;
          setState(() {
            _selectedStatus = status;
            _isLoading = true;
            _showRequestTypes = (status == 'pending');
            if (status == 'pending') {
              _requestType = 'borrow';
            }
          });
          _loadBorrowedBooks();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? statusColor
              : Colors.transparent, // Changed to transparent
          foregroundColor:
              isSelected ? Colors.white : statusColor, // Changed text color
          elevation: 0, // Removed elevation
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? statusColor
                  : statusColor
                      .withOpacity(0.3), // Made border semi-transparent
              width: 1.5,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24, // Reduced icon size
              color: isSelected ? Colors.white : statusColor,
            ),
            const SizedBox(height: 4), // Reduced spacing
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // Reduced font size
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : statusColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestTypeButton(String type, String label) {
    final isSelected = _requestType == type;
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _requestType = type;
            _isLoading = true;
          });
          _loadBorrowedBooks();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? primary : Colors.grey[100],
          foregroundColor: isSelected ? Colors.white : Colors.grey[800],
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(
              color: isSelected ? primary : Colors.grey[300]!,
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
    final isBorrowRequest = book != null &&
        _selectedStatus == 'pending' &&
        _requestType == 'borrow';

    final isReturnRequest = book != null &&
        _selectedStatus == 'pending' &&
        _requestType == 'return';

    final isPending = isBorrowRequest || isReturnRequest;

    // Get the appropriate book and user data based on request type
    final bookData =
        isReturnRequest ? book?['borrowed_books']?['books'] : book?['books'];

    final userData = isReturnRequest
        ? book?['borrowed_books']?['profiles']
        : book?['profiles'];

    final borrowId = isReturnRequest
        ? (book?['borrow_id'] ?? book?['borrowed_books']?['id'])
        : book?['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Dismissible(
        key: book != null ? Key(book['id'].toString()) : UniqueKey(),
        direction: isPending
            ? DismissDirection.horizontal
            : (_selectedStatus == 'borrowed'
                ? DismissDirection.endToStart
                : DismissDirection.none),
        confirmDismiss: (direction) async {
          if (book != null) {
            if (isPending) {
              // For pending requests, handle approve/reject
              if (direction == DismissDirection.endToStart) {
                // Reject request
                final requestType = isReturnRequest ? 'return' : 'borrow';
                // For return requests, allow admin notes
                if (isReturnRequest) {
                  final TextEditingController notesController =
                      TextEditingController();
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Reject ${requestType.capitalize()} Request'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Are you sure you want to reject this ${requestType} request?'),
                          const SizedBox(height: 16),
                          TextField(
                            controller: notesController,
                            decoration: const InputDecoration(
                              labelText: 'Admin Notes (Optional)',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context, {'confirmed': false}),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, {
                            'confirmed': true,
                            'notes': notesController.text,
                          }),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );

                  if (result != null && result['confirmed'] == true) {
                    _adminNotes = result['notes'];
                    return true;
                  }
                  return false;
                } else {
                  // Original dialog for borrow requests
                  return await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Reject ${requestType.capitalize()} Request'),
                      content: Text(
                          'Are you sure you want to reject this ${requestType} request?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Reject'),
                        ),
                      ],
                    ),
                  );
                }
              } else if (direction == DismissDirection.startToEnd) {
                // Similar changes for approval dialog
                final requestType = isReturnRequest ? 'return' : 'borrow';
                return await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Approve ${requestType.capitalize()} Request'),
                    content: Text('Approve this ${requestType} request?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                );
              }
            } else if (_selectedStatus == 'borrowed') {
              // For borrowed books, handle return
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
          }
          return false;
        },
        onDismissed: (direction) {
          if (book != null) {
            if (isPending) {
              if (direction == DismissDirection.endToStart) {
                if (isReturnRequest) {
                  _rejectReturnRequest(book['id']);
                } else {
                  _rejectBorrowRequest(book['id']);
                }
              } else if (direction == DismissDirection.startToEnd) {
                if (isReturnRequest) {
                  _approveReturnRequest(book['id'], borrowId);
                } else {
                  _approveBorrowRequest(book['id']);
                }
              }
            } else if (_selectedStatus == 'borrowed') {
              _markAsReturned(book['book_id'], book['user_id']);
            }
          }
        },
        background: isPending
            ? Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20.0),
                color: Colors.green,
                child: const Icon(Icons.check, color: Colors.white),
              )
            : Container(),
        secondaryBackground: isPending
            ? Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: Colors.red,
                child: const Icon(Icons.close, color: Colors.white),
              )
            : Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20.0),
                color: Colors.green,
                child: const Icon(Icons.check, color: Colors.white),
              ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Book Cover Image
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: bookData?['cover_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(bookData['cover_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[200],
                ),
                child: bookData?['cover_url'] == null
                    ? const Icon(Icons.book, size: 30, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookData?['title'] ?? 'Book Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${bookData?['author'] ?? 'Unknown Author'}',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 4),
                    Text(
                      'Borrowed by: ${userData?['full_name'] ?? 'User Name'}',
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
                        color: isBorrowRequest
                            ? Colors.orange.withOpacity(0.1)
                            : isReturnRequest
                                ? Colors.blue.withOpacity(0.1)
                                : secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isBorrowRequest
                            ? 'Borrow Request'
                            : isReturnRequest
                                ? 'Return Request'
                                : (book != null
                                    ? _getDaysLeft(book['due_date'])
                                    : '7 days left'),
                        style: TextStyle(
                          fontSize: 12,
                          color: isBorrowRequest
                              ? Colors.orange
                              : isReturnRequest
                                  ? Colors.blue
                                  : secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Add request date for return requests
                    if (isReturnRequest && book != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Requested: ${book['request_date'] != null ? _formatDate(book['request_date']) : 'Unknown date'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
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

  // Implement the missing _getDaysLeft method
  String _getDaysLeft(String dueDateStr) {
    try {
      final dueDate = DateTime.parse(dueDateStr);
      final now = DateTime.now();
      final difference = dueDate.difference(now).inDays;

      if (difference < 0) {
        return 'Overdue by ${-difference} days';
      } else if (difference == 0) {
        return 'Due today';
      } else if (difference == 1) {
        return '1 day left';
      } else {
        return '$difference days left';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Add the _formatDate method to format dates
  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  // Add the missing methods for handling borrow and return requests
  Future<void> _approveReturnRequest(int requestId, int borrowId) async {
    try {
      // Get the request details first
      final request = await Supabase.instance.client
          .from('return_requests')
          .select('*')
          .eq('id', requestId)
          .single();

      // Update the borrowed book status to returned
      await Supabase.instance.client.from('borrowed_books').update({
        'status': 'returned',
        'return_date': DateTime.now().toIso8601String(),
      }).eq('id', borrowId);

      // Update the return request status to approved
      await Supabase.instance.client.from('return_requests').update({
        'status': 'approved',
      }).eq('id', requestId);

      // Increment the book quantity
      await Supabase.instance.client.rpc('increment_book_quantity', params: {
        'book_id_param': request['book_id'],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request approved'),
          backgroundColor: Colors.green,
        ),
      );

      _loadBorrowedBooks();
    } catch (e) {
      print('Error approving return request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving return: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add this property to store admin notes temporarily
  String _adminNotes = '';

  Future<void> _rejectReturnRequest(int requestId) async {
    try {
      // Update the return request status to rejected
      await Supabase.instance.client.from('return_requests').update({
        'status': 'rejected',
        'admin_notes': _adminNotes.isNotEmpty ? _adminNotes : null,
      }).eq('id', requestId);

      // Reset admin notes
      _adminNotes = '';

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Return request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadBorrowedBooks();
    } catch (e) {
      print('Error rejecting return request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add the missing methods for handling borrow requests
  Future<void> _approveBorrowRequest(int borrowId) async {
    try {
      // Update borrow request status to borrowed
      await Supabase.instance.client.from('borrowed_books').update({
        'status': 'borrowed',
        'borrow_date': DateTime.now().toIso8601String(),
      }).eq('id', borrowId);

      // Get book id to decrement its quantity
      final borrowedBook = await Supabase.instance.client
          .from('borrowed_books')
          .select('book_id')
          .eq('id', borrowId)
          .single();

      // Decrement book quantity
      await Supabase.instance.client.rpc('decrement_book_quantity', params: {
        'book_id_param': borrowedBook['book_id'],
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrow request approved'),
          backgroundColor: Colors.green,
        ),
      );

      _loadBorrowedBooks();
    } catch (e) {
      print('Error approving borrow request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving borrow: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectBorrowRequest(int borrowId) async {
    try {
      // Update borrow request status to rejected
      await Supabase.instance.client.from('borrowed_books').update({
        'status': 'rejected',
      }).eq('id', borrowId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Borrow request rejected'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadBorrowedBooks();
    } catch (e) {
      print('Error rejecting borrow request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
