import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'user_homepage.dart';
import 'book_details_page.dart';

class FavoriteBooksPage extends StatefulWidget {
  const FavoriteBooksPage({super.key});

  @override
  State<FavoriteBooksPage> createState() => _FavoriteBooksPageState();
}

class _FavoriteBooksPageState extends State<FavoriteBooksPage> {
  final _supabase = Supabase.instance.client;
  String? _userId;
  List<Map<String, dynamic>> _favoriteBooks = [];
  bool _isLoading = true;
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
    _userId = _supabase.auth.currentUser?.id;
    _loadFavoriteBooks();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (!mounted) return;
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

  Future<void> _loadFavoriteBooks() async {
    if (_userId == null || !mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _supabase
          .from('favorites')
          .select('*, books(*)')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        _favoriteBooks = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading favorite books: $e');
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildFavoriteBookCard(Map<String, dynamic>? book) {
    if (book == null) {
      // Loading skeleton
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 70,
                height: 100,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: const Icon(Icons.book, size: 35, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 16, width: 150, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 100, color: Colors.grey[300]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 80, color: Colors.grey[300]),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final bookData = book['books'] as Map<String, dynamic>;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: SizedBox(
        height: 140,
        child: Dismissible(
          key: Key(book['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            decoration: BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.delete_rounded, color: Colors.white),
          ),
          confirmDismiss: (direction) => showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Removal'),
              content: const Text('Remove this book from favorites?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: primary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remove', style: TextStyle(color: primary)),
                ),
              ],
            ),
          ),
          onDismissed: (_) => _removeFavorite(book),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BookDetailsPage(
                    book: Book(
                      id: bookData['id'],
                      title: bookData['title'],
                      author: bookData['author'],
                      description: bookData['description'],
                      coverUrl: bookData['image_url'],
                      genre: bookData['genre'],
                      year: bookData['year'],
                      quantity: bookData['quantity'],
                    ),
                  ),
                ),
              ).then((_) => _loadFavoriteBooks());
            },
            child: Container(
              child: Row(
                children: [
                  // Book Cover
                  Container(
                    width: 95,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        bookData['image_url'] ?? '',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              color: primary,
                              strokeWidth: 2,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.book_rounded,
                              size: 35,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookData['title'] ?? 'Unknown Title',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'By ${bookData['author'] ?? 'Unknown Author'}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bookData['genre'] ?? 'Unknown Genre',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (bookData['quantity'] ?? 0) > 0
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            (bookData['quantity'] ?? 0) > 0
                                ? 'Available'
                                : 'Not Available',
                            style: TextStyle(
                              fontSize: 12,
                              color: (bookData['quantity'] ?? 0) > 0
                                  ? primary
                                  : Colors.red,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    padding: const EdgeInsets.all(10),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        color: secondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _removeFavorite(book),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _removeFavorite(Map<String, dynamic> book) async {
    if (_userId == null || !mounted) return;

    try {
      await _supabase.from('favorites').delete().eq('id', book['id']);

      if (!mounted) return;
      setState(() {
        _favoriteBooks.removeWhere((b) => b['id'] == book['id']);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${book['books']['title']} removed from favorites'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error removing from favorites: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get _filteredBooks {
    return _favoriteBooks.where((book) {
      final bookData = book['books'] as Map<String, dynamic>;
      final matchesSearch = _searchQuery.isEmpty ||
          bookData['title']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          bookData['author']
              .toString()
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      final matchesCategory = selectedCategory == null ||
          selectedCategory == 'All' ||
          bookData['genre'] == selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Favorite Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondary,
        elevation: 4,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15.0, 15.0, 15.0, 5),
            child: Container(
              decoration: BoxDecoration(
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
              child: TextField(
                controller: _searchController,
                cursorColor: primary,
                decoration: InputDecoration(
                  hintText: 'Search favorites...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.search, color: secondary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _isLoading ? 6 : categories.length,
              itemBuilder: (context, index) {
                IconData categoryIcon = _getCategoryIcon(categories[index]);
                Color categoryColors =
                    categoryColor[categories[index]] ?? Colors.blue;

                return Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategory = categories[index];
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
              },
            ),
          ),
          Expanded(
            child: Skeletonizer(
              enabled: _isLoading,
              child: _isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 80), // Added bottom padding
                      itemCount: 3,
                      itemBuilder: (context, index) =>
                          _buildFavoriteBookCard(null),
                    )
                  : _filteredBooks.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(
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
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                          itemCount: _filteredBooks.length,
                          itemBuilder: (context, index) {
                            final book = _filteredBooks[index];
                            return _buildFavoriteBookCard(book);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return '${date.day}/${date.month}/${date.year}';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return Icons.apps_rounded;
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
}
