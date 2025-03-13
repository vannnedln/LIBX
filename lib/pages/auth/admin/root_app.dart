import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/admin/admin_dashboard.dart';
import 'package:libx_final/pages/auth/admin/admin_profile_settings.dart';
import 'package:libx_final/pages/auth/admin/all_books.dart';
import 'package:libx_final/pages/auth/admin/borrowed_books_page.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:libx_final/pages/auth/admin/add_book_page.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:libx_final/utils/role_checker_mixin.dart';

class RootApp extends StatefulWidget {
  const RootApp({super.key});

  @override
  State<RootApp> createState() => _RootAppState();
}

class _RootAppState extends State<RootApp> with RoleCheckerMixin {
  int pageIndex = 0;
  final GlobalKey<AllBooksState> allBooksKey = GlobalKey<AllBooksState>();

  @override
  void initState() {
    super.initState();
    checkRole('admin'); // Add this line
  }

  // Add dispose method to clean up resources
  @override
  void dispose() {
    allBooksKey.currentState?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: getBody(),
      ),
      bottomNavigationBar: getFooter(),
      floatingActionButton: pageIndex != 3
          ? Padding(
              padding: const EdgeInsets.only(bottom: 15),
              child: SizedBox(
                width: 65,
                height: 65,
                child: FloatingActionButton(
                  onPressed: () async {
                    if (!mounted) return;
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddBookPage(
                          onBookAdded: () {
                            // Remove this callback as we'll handle refresh after navigation
                          },
                        ),
                      ),
                    );

                    // Check mounted state and refresh books after navigation
                    if (mounted) {
                      final currentState = allBooksKey.currentState;
                      if (currentState != null && currentState.mounted) {
                        currentState.fetchBooks();
                      }
                    }
                  },
                  backgroundColor: secondary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }

  Widget getBody() {
    List<Widget> pages = [
      AdminDashboard(),
      AllBooks(key: allBooksKey),
      BorrowedBooksPage(),
      AdminProfilePage(
        onBack: () => setTabs(0),
      ),
    ];
    return pages[pageIndex];
  }

  Widget getFooter() {
    List<Widget> items = [
      ImageIcon(
        const AssetImage('assets/images/home_icon.png'),
        size: 25,
        color: Colors.white,
      ),
      ImageIcon(
        const AssetImage('assets/images/book_icon.png'),
        size: 25,
        color: Colors.white,
      ),
      ImageIcon(
        const AssetImage('assets/images/list_icon.png'),
        size: 25,
        color: Colors.white,
      ),
      ImageIcon(
        const AssetImage('assets/images/person_icon.png'),
        size: 25,
        color: Colors.white,
      ),
    ];

    return CurvedNavigationBar(
      backgroundColor: Colors.transparent,
      color: secondary,
      buttonBackgroundColor: secondary,
      height: 60,
      animationDuration: const Duration(milliseconds: 300),
      items: items,
      index: pageIndex,
      onTap: (index) => setTabs(index),
    );
  }

  void setTabs(int index) {
    if (mounted) {
      // Add mounted check
      setState(() {
        pageIndex = index;
      });
    }
  }
}
