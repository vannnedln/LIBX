import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/user/book_details_page.dart';
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
    await fetchBooks();
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
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const CircleAvatar(
                              radius: 24,
                              backgroundImage:
                                  AssetImage('assets/images/person_icon.png'),
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
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_rounded),
                              color: secondary,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      title: const Row(
                                        children: [
                                          Icon(Icons.notifications,
                                              color: secondary),
                                          SizedBox(width: 10),
                                          Text('Notifications'),
                                        ],
                                      ),
                                      content: SizedBox(
                                        width: double.maxFinite,
                                        child: ListView(
                                          shrinkWrap: true,
                                          children: [
                                            _buildNotificationItem(
                                              'Book Due Tomorrow',
                                              'The Great Gatsby is due tomorrow',
                                              Icons.warning,
                                              Colors.orange,
                                            ),
                                            const Divider(),
                                            _buildNotificationItem(
                                              'New Book Available',
                                              'Check out our latest addition!',
                                              Icons.new_releases,
                                              Colors.green,
                                            ),
                                          ],
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: const Text('Close'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

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
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              cursorColor: primary,
                              decoration: InputDecoration(
                                hintText: 'Search Books...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                prefixIcon:
                                    Icon(Icons.search, color: secondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Top Available Books Section
                  Skeletonizer(
                    enabled: isLoading,
                    child: _buildSectionHeader('Top Available for you!',
                        onViewAll: () {}),
                  ),
                  const SizedBox(height: 16),
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      height: 230,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: availableBooks.length,
                        itemBuilder: (context, index) {
                          final book = availableBooks[index];
                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookDetailsPage(
                                  book: book,
                                ),
                              ),
                            ),
                            child: Container(
                              width: 140,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 0,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12),
                                    ),
                                    child: Image.network(
                                      book.coverUrl,
                                      height: 150,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                        return Container(
                                          height: 130,
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
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          book.title,
                                          style: const TextStyle(
                                            fontSize:
                                                14, // Slightly reduced from 14
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(
                                            height: 4), // Reduced from 4
                                        Text(
                                          book.author,
                                          style: TextStyle(
                                            fontSize:
                                                12, // Slightly reduced from 12
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
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
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          final genres = [
                            (
                              'Biographies',
                              Icons.person_outline,
                              Colors.amberAccent
                            ),
                            ('Fiction', Icons.auto_stories, Colors.greenAccent),
                            ('Engineering', Icons.engineering, Colors.blueGrey),
                            ('History', Icons.history_edu, Colors.brown),
                            (
                              'Romance',
                              Icons.favorite_outline,
                              Colors.redAccent
                            ),
                          ];
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 16),
                            child: _buildGenreCard(
                              genres[index].$1,
                              genres[index].$2,
                              genres[index].$3,
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
                    child: _buildSectionHeader('Your Recently Borrowed Books',
                        onViewAll: () {}),
                  ),
                  const SizedBox(height: 16),
                  Skeletonizer(
                    enabled: isLoading,
                    child: SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 4,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 140,
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
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    'https://marketplace.canva.com/EAFfSnGl7II/2/0/1003w/canva-elegant-dark-woods-fantasy-photo-book-cover-vAt8PH1CmqQ.jpg',
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
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
                                      color: primary.withOpacity(0.8),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      '${3 + index} Days Left',
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
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            print('Selected genre: $title');
          },
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

  Widget _buildNotificationItem(
    String title,
    String subtitle,
    IconData icon,
    Color iconColor,
  ) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(subtitle),
      onTap: () {
        // Handle notification tap
        print('Notification tapped: $title');
      },
    );
  }
}
