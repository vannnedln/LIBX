import 'package:flutter/material.dart';
import 'package:libx_final/pages/auth/user/borrowed_books_page.dart';
import 'package:libx_final/pages/auth/user/browse_books_page.dart';
import 'package:libx_final/pages/auth/user/favorite_books_page.dart';
import 'package:libx_final/pages/auth/user/user_homepage.dart';
import 'package:libx_final/pages/auth/user/user_profile_page.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:libx_final/utils/role_checker_mixin.dart';

class UserRootApp extends StatefulWidget {
  final String firstName;
  const UserRootApp({
    super.key,
    required this.firstName,
  });

  @override
  State<UserRootApp> createState() => _UserRootAppState();
}

class _UserRootAppState extends State<UserRootApp> with RoleCheckerMixin {
  int pageIndex = 0;

  @override
  void initState() {
    super.initState();
    checkRole('user');
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
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BrowseBooksPage(),
                      ),
                    );
                  },
                  backgroundColor: secondary,
                  elevation: 6,
                  shape: const CircleBorder(),
                  child: const Icon(
                    Icons.search_rounded,
                    color: Colors.white,
                    size: 35,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget getBody() {
    return IndexedStack(
      index: pageIndex,
      children: [
        UserHomepage(firstName: widget.firstName),
        const BorrowedBooksPage(),
        const FavoriteBooksPage(),
        const UserProfilePage(),
      ],
    );
  }

  @override
  void dispose() {
    // Clean up any listeners or subscriptions here
    super.dispose();
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
        const AssetImage('assets/images/heart_icon.png'),
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
    setState(() {
      pageIndex = index;
    });
  }
}
