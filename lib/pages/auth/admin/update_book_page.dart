import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'dart:typed_data';

class UpdateBookPage extends StatefulWidget {
  final Map<String, dynamic> book;
  final Function? onBookUpdated;

  const UpdateBookPage({
    super.key,
    required this.book,
    this.onBookUpdated,
  });

  @override
  State<UpdateBookPage> createState() => _UpdateBookPageState();
}

class _UpdateBookPageState extends State<UpdateBookPage> {
  // Add categories list
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
    'Historical Fiction',
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

  final titleController = TextEditingController();
  final authorController = TextEditingController();
  final genreController = TextEditingController();
  final yearController = TextEditingController();
  final descriptionController = TextEditingController();
  final quantityController = TextEditingController();

  final supabase = Supabase.instance.client;
  Uint8List? imageBytes;
  String? imageName;
  String? currentImageUrl;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing book data
    titleController.text = widget.book['title'] ?? '';
    authorController.text = widget.book['author'] ?? '';
    genreController.text = widget.book['genre'] ?? '';
    yearController.text = widget.book['year']?.toString() ?? '';
    descriptionController.text = widget.book['description'] ?? '';
    quantityController.text = widget.book['quantity']?.toString() ?? '';
    currentImageUrl = widget.book['image_url'];
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final Uint8List bytes = await pickedFile.readAsBytes();
      setState(() {
        imageBytes = bytes;
        imageName = pickedFile.name;
      });
    }
  }

  Future<String?> _uploadBookImage() async {
    if (imageBytes == null) return currentImageUrl;

    try {
      final String fileName =
          'book_covers/${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('libx_image').uploadBinary(
            fileName,
            imageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
              cacheControl: '3600',
            ),
          );

      return supabase.storage.from('libx_image').getPublicUrl(fileName);
    } catch (e) {
      print("Image Upload Failed: $e");
      await QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Upload Failed',
        text: 'Failed to upload image. Please try again.',
        confirmBtnColor: primary,
      );
      return null;
    }
  }

  Future<void> _updateBook() async {
    setState(() => isLoading = true);

    try {
      // Check each field individually
      if (titleController.text.trim().isEmpty) {
        throw 'Book title is required';
      }
      if (authorController.text.trim().isEmpty) {
        throw 'Author name is required';
      }
      if (genreController.text.trim().isEmpty) {
        throw 'Genre is required';
      }
      if (yearController.text.trim().isEmpty) {
        throw 'Year is required';
      }
      if (quantityController.text.trim().isEmpty) {
        throw 'Quantity is required';
      }
      if (descriptionController.text.trim().isEmpty) {
        throw 'Description is required';
      }

      // Rest of the validation and update logic
      final year = int.tryParse(yearController.text);
      if (year == null || year < 1000 || year > DateTime.now().year) {
        throw 'Please enter a valid year';
      }

      // Validate quantity
      final quantity = int.tryParse(quantityController.text);
      if (quantity == null || quantity < 0) {
        throw 'Please enter a valid quantity';
      }

      final String? imageUrl = await _uploadBookImage();

      // Update book data in database
      await supabase.from('books').update({
        'title': titleController.text,
        'author': authorController.text,
        'genre': genreController.text,
        'description': descriptionController.text,
        'year': year,
        'quantity': quantity,
        if (imageUrl != null) 'image_url': imageUrl,
      }).eq('id', widget.book['id']);

      if (!mounted) return;
      widget.onBookUpdated?.call();

      await QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Book updated successfully!',
        confirmBtnColor: primary,
      );

      Navigator.pop(context);
    } catch (error) {
      print('Error details: $error');
      if (!mounted) return;

      await QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: error.toString(),
        confirmBtnColor: primary,
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        FocusScope.of(context).unfocus();
        return true;
      },
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text(
              'EDIT BOOK',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: secondary,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () {
                FocusScope.of(context).unfocus();
                Navigator.pop(context);
              },
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                          image: imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : (currentImageUrl != null)
                                  ? DecorationImage(
                                      image: NetworkImage(currentImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                        ),
                        child: (imageBytes == null && currentImageUrl == null)
                            ? const Center(
                                child: Icon(Icons.add_photo_alternate,
                                    size: 50, color: Colors.grey),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _pickImage,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Book details section
                const Text(
                  'Book Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                // Required fields
                TextField(
                  controller: titleController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Book Title',
                    labelStyle: TextStyle(color: primary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: authorController,
                  cursorColor: primary,
                  decoration: InputDecoration(
                    labelText: 'Author',
                    labelStyle: TextStyle(color: primary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 15),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      value: categories.contains(genreController.text)
                          ? genreController.text
                          : null,
                      hint: Text('Genre', style: TextStyle(color: primary)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                      ),
                      items: categories
                          .where((category) => category != 'All')
                          .map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (String? value) {
                        setState(() {
                          genreController.text = value ?? '';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Year and Quantity in Row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: yearController,
                        cursorColor: primary,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Year',
                          labelStyle: TextStyle(color: primary),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onTap: () async {
                          final DateTime? picked = await showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                backgroundColor: Colors.white,
                                title: const Text("Select Year"),
                                content: Container(
                                  height: 300,
                                  width: 300,
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: Theme.of(context)
                                          .colorScheme
                                          .copyWith(
                                            primary: secondary,
                                          ),
                                    ),
                                    child: YearPicker(
                                      firstDate: DateTime(1000),
                                      lastDate: DateTime.now(),
                                      selectedDate: yearController.text.isEmpty
                                          ? DateTime.now()
                                          : DateTime(
                                              int.parse(yearController.text)),
                                      onChanged: (DateTime dateTime) {
                                        setState(() {
                                          yearController.text =
                                              dateTime.year.toString();
                                        });
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: quantityController,
                        cursorColor: primary,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          labelStyle: TextStyle(color: primary),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: primary),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                // Description field
                TextField(
                  controller: descriptionController,
                  cursorColor: primary,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    alignLabelWithHint: true,
                    labelStyle: TextStyle(color: primary),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: primary),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Update button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _updateBook,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mode_edit_outline_rounded,
                                  size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Update Book',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
