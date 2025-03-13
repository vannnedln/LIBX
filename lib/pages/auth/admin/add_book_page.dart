import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:quickalert/models/quickalert_type.dart';
import 'package:quickalert/widgets/quickalert_dialog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddBookPage extends StatefulWidget {
  final Function? onBookAdded;
  const AddBookPage({super.key, this.onBookAdded});

  @override
  State<AddBookPage> createState() => _AddBookPageState();
}

class _AddBookPageState extends State<AddBookPage> {
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
  bool isLoading = false;
  final ImagePicker picker = ImagePicker();
  Uint8List? imageBytes;
  String? imageName;
  Future<void> _pickImage() async {
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
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
    if (imageBytes == null) return null;

    try {
      final String fileName =
          'book_covers/${DateTime.now().millisecondsSinceEpoch}.jpg'; // Changed path
      await supabase.storage.from('libx_image').uploadBinary(
            fileName,
            imageBytes!,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
              cacheControl: '3600', // Added cache control
            ),
          );

      return supabase.storage.from('libx_image').getPublicUrl(fileName);
    } catch (e) {
      print("Image Upload Failed: $e");
      return null;
    }
  }

  Future<void> _uploadBook() async {
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
      if (imageBytes == null) {
        throw 'Please select an image';
      }

      // Validate year
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
      if (imageUrl == null) throw 'Failed to upload image';

      await supabase.from('books').insert({
        'title': titleController.text,
        'author': authorController.text,
        'genre': genreController.text,
        'description': descriptionController.text,
        'year': int.tryParse(yearController.text) ?? 0,
        'quantity': int.tryParse(quantityController.text) ?? 0,
        'image_url': imageUrl,
      });

      if (!mounted) return;
      widget.onBookAdded?.call();

      await QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        title: 'Success',
        text: 'Book added successfully!',
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
              'ADD BOOK',
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
                // Image picker section
                Stack(
                  children: [
                    GestureDetector(
                      onTap: imageBytes != null
                          ? () {
                              showDialog(
                                context: context,
                                builder: (context) => Dialog(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.memory(
                                        imageBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          : _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                          image: imageBytes != null
                              ? DecorationImage(
                                  image: MemoryImage(imageBytes!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageBytes == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.add_photo_alternate_rounded,
                                      size: 80),
                                  SizedBox(height: 10),
                                  Text(
                                    'Add Book Cover',
                                    style: TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : null,
                      ),
                    ),
                    if (imageBytes != null)
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
                      borderRadius: BorderRadius.circular(10),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Add button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _uploadBook,
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
                              Icon(Icons.save_alt_rounded,
                                  size: 20, color: Colors.white), // Save icon
                              SizedBox(width: 8), // Space between icon and text
                              Text(
                                'Add Book',
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
