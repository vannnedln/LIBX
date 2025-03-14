import 'package:flutter/material.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:libx_final/pages/auth/admin/update_book_page.dart';
import 'package:quickalert/quickalert.dart';

class AllBooks extends StatefulWidget {
  const AllBooks({super.key});

  @override
  AllBooksState createState() => AllBooksState();
}

class AllBooksState extends State<AllBooks> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> books = [];
  List<dynamic> filteredBooks = [];
  final TextEditingController searchController = TextEditingController();
  bool isLoading = true; // Track loading state
  // Add these variables at the top of the class
  String? selectedCategory;
  bool? showAvailableOnly;
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

  // Add this map for category colors

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

  // ... rest of the code remains the same ...
  // Add this method inside the class
  void _applyFilters() {
    setState(() {
      filteredBooks = books.where((book) {
        bool categoryMatch =
            selectedCategory == null || selectedCategory == 'All'
                ? true
                : book['genre'] == selectedCategory;

        bool availabilityMatch =
            showAvailableOnly == null || !showAvailableOnly!
                ? true
                : (book['quantity'] ?? 0) > 0;

        return categoryMatch && availabilityMatch;
      }).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchBooks(); // Fetch books when widget is initialized
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _navigateToUpdateBook(Map<String, dynamic> book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UpdateBookPage(
          book: book,
          onBookUpdated: () {
            fetchBooks(); // Refresh the books list after update
          },
        ),
      ),
    );
  }

  Future<void> fetchBooks() async {
    setState(() => isLoading = true);

    final response =
        await supabase.from('books').select().order('id', ascending: false);

    setState(() {
      books = response;
      filteredBooks = response;
      _applyFilters();
      isLoading = false;
    });
  }

  void showBooksDialog(BuildContext context,
      {int? id,
      String? title,
      String? author,
      String? genre,
      int? year,
      String? description,
      int? quantity}) {
    final titleController = TextEditingController(text: title);
    final authorController = TextEditingController(text: author);
    final genreController = TextEditingController(text: genre);
    final yearController = TextEditingController(text: year?.toString() ?? '');
    final descriptionController = TextEditingController(text: description);
    final quantityController =
        TextEditingController(text: quantity?.toString() ?? '');
    final imageUrlController = TextEditingController(text: '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          id == null ? 'Add Book' : 'Edit Book',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: titleController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Book Title',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: imageUrlController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Book Cover Image URL',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: authorController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: genreController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Genre',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: descriptionController,
                  cursorColor: primary,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: yearController,
                  cursorColor: primary,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Year Published',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: TextField(
                  controller: quantityController,
                  cursorColor: primary,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    labelStyle: TextStyle(color: primary),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final data = {
                  'title': titleController.text,
                  'author': authorController.text,
                  'genre': genreController.text,
                  'description': descriptionController.text,
                  'year': int.tryParse(yearController.text) ?? 0,
                  'quantity': int.tryParse(quantityController.text) ?? 0,
                  'image_url': imageUrlController.text,
                };

                if (id == null) {
                  await supabase.from('books').insert(data);
                } else {
                  await supabase.from('books').update(data).match({'id': id});
                }

                if (!context.mounted) return;
                Navigator.pop(context);
                fetchBooks();

                // Replace SnackBar with QuickAlert
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.success,
                  title: 'Success',
                  text: id == null
                      ? 'Book added successfully!'
                      : 'Book updated successfully!',
                  confirmBtnColor: primary,
                );
              } catch (error) {
                if (!context.mounted) return;
                // Replace error SnackBar with QuickAlert
                await QuickAlert.show(
                  context: context,
                  type: QuickAlertType.error,
                  title: 'Error',
                  text: error.toString(),
                  confirmBtnColor: primary,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(id == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'All Books',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: secondary,
        elevation: 4,
      ),
      backgroundColor: background,
      body: RefreshIndicator(
        color: primary,
        backgroundColor: Colors.white,
        onRefresh: fetchBooks,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: searchController,
                      onChanged: (query) {
                        setState(() {
                          filteredBooks = books
                              .where((book) =>
                                  book['title']
                                      .toLowerCase()
                                      .contains(query.toLowerCase()) ||
                                  book['author']
                                      .toLowerCase()
                                      .contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                      cursorColor: primary,
                      decoration: InputDecoration(
                        hintText: 'Search Books...',
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
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
                          _applyFilters();
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
                                fontWeight:
                                    selectedCategory == categories[index]
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
                child: isLoading
                    ? Skeletonizer(
                        enabled: true,
                        child: ListView.builder(
                          itemCount: 6,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(15),
                                        bottomLeft: Radius.circular(15),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          height: 20,
                                          width: 150,
                                          color: Colors.grey[300],
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 15,
                                          width: 100,
                                          color: Colors.grey[300],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 30),
                        itemCount: filteredBooks.length,
                        itemBuilder: (context, index) {
                          final book = filteredBooks[index];
                          return Dismissible(
                            key: Key(book['id'].toString()),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              height: 120,
                              margin: const EdgeInsets.only(bottom: 25),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.white,
                              ),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    title: const Text("Confirm Delete"),
                                    content: const Text(
                                        "Are you sure you want to delete this book?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text(
                                          "Cancel",
                                          style: TextStyle(color: primary),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          "Delete",
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            onDismissed: (direction) {
                              _deleteBook(book);
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 25),
                              child: GestureDetector(
                                onTap: () => _navigateToUpdateBook(book),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 100),
                                          Expanded(
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    book['title'],
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'By ${book['author']}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                      fontStyle:
                                                          FontStyle.italic,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          (book['quantity'] ??
                                                                      0) >
                                                                  0
                                                              ? Colors.green
                                                                  .withOpacity(
                                                                      0.1)
                                                              : Colors.red
                                                                  .withOpacity(
                                                                      0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: Text(
                                                      (book['quantity'] ?? 0) >
                                                              0
                                                          ? '${book['quantity']} Available'
                                                          : 'Not Available',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            (book['quantity'] ??
                                                                        0) >
                                                                    0
                                                                ? Colors.green
                                                                : Colors.red,
                                                        fontWeight:
                                                            FontWeight.w500,
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
                                    Positioned(
                                      left: 15,
                                      top: -15,
                                      child: Container(
                                        width: 85,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.2),
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: Image.network(
                                            book['image_url'] ?? '',
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child,
                                                loadingProgress) {
                                              if (loadingProgress == null)
                                                return child;
                                              return Container(
                                                color: Colors.grey[200],
                                                child: Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    value: loadingProgress
                                                                .expectedTotalBytes !=
                                                            null
                                                        ? loadingProgress
                                                                .cumulativeBytesLoaded /
                                                            loadingProgress
                                                                .expectedTotalBytes!
                                                        : null,
                                                    color: primary,
                                                    strokeWidth: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                            errorBuilder:
                                                (context, error, stackTrace) {
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
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBook(Map<String, dynamic> book) async {
    try {
      await supabase.from('books').delete().match({'id': book['id']});
      fetchBooks(); // Refresh the list
      if (!mounted) return;

      await QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Book deleted successfully!',
        confirmBtnColor: primary,
      );
    } catch (error) {
      if (!mounted) return;

      await QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Error deleting book: $error',
        confirmBtnColor: primary,
      );
    }
  }
}

// Add this method to your AllBooksState class
IconData _getCategoryIcon(String category) {
  switch (category.toLowerCase()) {
    case 'all':
      return Icons.category_rounded;
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
