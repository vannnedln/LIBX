import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:libx_final/theme/colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _genreData = [];
  Map<DateTime, int> _borrowedData = {};
  Map<DateTime, int> _returnedData = {};
  String _errorMessage = '';
  String? _userAvatarUrl; // Add this
  String _firstName = ''; // Add this
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _fetchUserProfile(); // Add this
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('profiles')
          .select('avatar_url, first_name, role')
          .eq('id', userId)
          .eq('role', 'admin')
          .single();

      if (!mounted) return;
      if (response != null) {
        setState(() {
          _userAvatarUrl = response['avatar_url'];
          _firstName = response['first_name'] ?? 'Admin';
        });
      }
    } catch (error) {
      print('Error fetching user profile: $error');
      if (!mounted) return;
      setState(() {
        _firstName = 'Admin';
      });
    }
  }

  // In the build method, update the body to include the profile card
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: secondary,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDashboardData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadDashboardData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Add the profile card here
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: secondary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 1),
                                ),
                                child: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: Colors.grey[200],
                                  backgroundImage: _userAvatarUrl != null
                                      ? NetworkImage(_userAvatarUrl!)
                                      : null,
                                  child: _userAvatarUrl == null
                                      ? Icon(
                                          Icons.person_rounded,
                                          size: 30,
                                          color: secondary,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Welcome back,',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    _firstName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildStatSummary(),
                        const SizedBox(height: 10),
                        _buildGenreChart(),
                        const SizedBox(height: 10),
                        _buildBorrowReturnChart(),
                        const SizedBox(
                          height: 80,
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  @override
  void dispose() {
    // Cancel any pending operations
    _isLoading = false;
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
<<<<<<< HEAD
    if (!mounted) return;
=======
    if (!mounted) return; // Add this check at the start
>>>>>>> 35211c29b7affcf144888a85fce619cb64a414e3

    try {
      if (!mounted) return; // Check mounted before setState
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Load genre data
      final genreResponse = await Supabase.instance.client
          .from('books')
          .select('genre')
          .not('genre', 'is', null);

      if (!mounted) return; // Check mounted after async operation

      // Count genres
      final genreCounts = <String, int>{};
      for (final book in genreResponse) {
        final genre = book['genre'] as String;
        genreCounts[genre] = (genreCounts[genre] ?? 0) + 1;
      }

      // Convert to list and sort by count
      final newGenreData = genreCounts.entries
          .map((e) => {'genre': e.key, 'count': e.value})
          .toList()
        ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      // Load borrowed and returned books data
      final DateTime now = DateTime.now();
      final DateTime sevenDaysAgo = now.subtract(const Duration(days: 7));

      final borrowedResponse = await Supabase.instance.client
          .from('borrowed_books')
          .select('borrow_date')
          .gte('borrow_date', sevenDaysAgo.toIso8601String());

      if (!mounted) return; // Check mounted after async operation

      final returnedResponse = await Supabase.instance.client
          .from('borrowed_books')
          .select('return_date')
          .eq('status', 'returned')
          .not('return_date', 'is', null)
          .gte('return_date', sevenDaysAgo.toIso8601String());

      if (!mounted) return; // Check mounted after async operation

      // Process borrowed books data
      final Map<DateTime, int> newBorrowedData = {};
      for (final book in borrowedResponse) {
        if (book['borrow_date'] != null) {
          final date = DateTime.parse(book['borrow_date']).dateOnly;
          newBorrowedData[date] = (newBorrowedData[date] ?? 0) + 1;
        }
      }

      // Process returned books data
      final Map<DateTime, int> newReturnedData = {};
      for (final book in returnedResponse) {
        if (book['return_date'] != null) {
          final date = DateTime.parse(book['return_date']).dateOnly;
          newReturnedData[date] = (newReturnedData[date] ?? 0) + 1;
        }
      }

<<<<<<< HEAD
      if (_mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (_mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load dashboard data. Please try again.';
        });
      }
=======
      if (!mounted) return; // Final mounted check before setState
      setState(() {
        _genreData = newGenreData;
        _borrowedData = newBorrowedData;
        _returnedData = newReturnedData;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (!mounted) return; // Check mounted before error setState
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load dashboard data. Please try again.';
      });
>>>>>>> 35211c29b7affcf144888a85fce619cb64a414e3
    }
  }

  Widget _buildStatSummary() {
    final totalBooks =
        _genreData.fold(0, (sum, item) => sum + (item['count'] as int));
    final totalBorrowed =
        _borrowedData.values.fold(0, (sum, count) => sum + count);
    final totalReturned =
        _returnedData.values.fold(0, (sum, count) => sum + count);
    return Column(
      children: [
        _buildStatCard('Total Books', totalBooks.toString(), Icons.book_rounded,
            Colors.blue),
        const SizedBox(height: 16),
        _buildStatCard('Borrowed (7d)', totalBorrowed.toString(),
            Icons.upload_rounded, Colors.orange),
        const SizedBox(height: 16),
        _buildStatCard(
          'Returned (7d)',
          totalReturned.toString(),
          Icons.download_rounded,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenreChart() {
    if (_genreData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('No genre data available'),
          ),
        ),
      );
    }
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Books by Genre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: _genreData.map((data) {
                    final total = _genreData.fold(
                        0, (sum, item) => sum + (item['count'] as int));
                    final percentage = (data['count'] as int) / total * 100;
                    return PieChartSectionData(
                      color: Colors.primaries[
                          _genreData.indexOf(data) % Colors.primaries.length],
                      value: data['count'].toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _genreData.map((data) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.primaries[
                            _genreData.indexOf(data) % Colors.primaries.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${data['genre']} (${data['count']})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBorrowReturnChart() {
    final List<FlSpot> borrowedSpots = [];
    final List<FlSpot> returnedSpots = [];
    double maxY = 0;

    // Ensure we have data for all 7 days
    for (int i = 6; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i)).dateOnly;
      final borrowedCount = _borrowedData[date] ?? 0;
      final returnedCount = _returnedData[date] ?? 0;
      borrowedSpots.add(FlSpot((6 - i).toDouble(), borrowedCount.toDouble()));
      returnedSpots.add(FlSpot((6 - i).toDouble(), returnedCount.toDouble()));
      maxY = [maxY, borrowedCount.toDouble(), returnedCount.toDouble()]
          .reduce((max, value) => value > max ? value : max);
    }

    if (maxY == 0) maxY = 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Book Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Last 7 Days',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.15),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final date = DateTime.now()
                              .subtract(Duration(days: (6 - value).toInt()));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        interval: 1,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: maxY > 5 ? maxY / 5 : 1,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value == value.roundToDouble()) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: maxY + (maxY > 0 ? maxY * 0.1 : 1),
                  lineBarsData: [
                    LineChartBarData(
                      spots: borrowedSpots,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: returnedSpots,
                      isCurved: true,
                      color: Colors.green,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) =>
                            FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.green,
                        ),
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Borrowed', Colors.blue),
                const SizedBox(width: 24),
                _buildLegendItem('Returned', Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}

extension DateTimeExtension on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);
}
