import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:libx_final/pages/auth/user/book_details_page.dart';
import 'package:libx_final/pages/auth/user/user_homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BrowseBooksPage extends StatefulWidget {
  const BrowseBooksPage({super.key});

  @override
  State<BrowseBooksPage> createState() => _BrowseBooksPageState();
}

class _BrowseBooksPageState extends State<BrowseBooksPage> {
  final _supabase = Supabase.instance.client;
  List<Book> books = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBooks();
  }

  Future<void> fetchBooks() async {
    try {
      final response = await _supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);

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
                        ? DateTime.parse(book['created_at'])
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // Reduced padding
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_rounded,
                            color: primary),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        // Wrapped with Expanded
                        child: Text(
                          'Browse Books',
                          style: TextStyle(
                            fontSize: 24, // Reduced font size
                            fontWeight: FontWeight.bold,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // Reduced spacing
                  // Search bar container
                  Container(
                    height: 60, // Increased height from 50 to 60
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
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, // Increased horizontal padding
                                vertical: 12, // Increased vertical padding
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: secondary))
                  : books.isEmpty
                      ? const Center(child: Text('No books available'))
                      : GridView.builder(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4, // Reduced from 8
                          ),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.40,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 12, // Reduced from 16
                          ),
                          itemCount: books.length,
                          itemBuilder: (context, index) {
                            final book = books[index];
                            return GestureDetector(
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(12),
                                          ),
                                          image: DecorationImage(
                                            image: NetworkImage(book.coverUrl),
                                            fit: BoxFit.cover,
                                            onError: (exception, stackTrace) =>
                                                const AssetImage(
                                                    'assets/images/book_placeholder.png'),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              book.title,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: primary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              book.author,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: book.quantity > 0
                                                    ? accent.withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                book.quantity > 0
                                                    ? 'Available'
                                                    : 'Unavailable',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: book.quantity > 0
                                                      ? secondary
                                                      : Colors.red,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
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
          ],
        ),
      ),
    );
  }
}
