import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/theme.dart';
import '../../providers/report_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/report_card.dart';

class ReportsListPage extends StatefulWidget {
  const ReportsListPage({super.key});

  @override
  State<ReportsListPage> createState() => _ReportsListPageState();
}

class _ReportsListPageState extends State<ReportsListPage> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedType = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final reportProvider = Provider.of<ReportProvider>(context, listen: false);
      if (userProvider.currentUser != null) {
        reportProvider.loadReports(userProvider.currentUser!.userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reportProvider = Provider.of<ReportProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        title: const Text('My Reports'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search reports...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: StreamBuilder(
              stream: reportProvider.getReportsStream(userProvider.currentUser!.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading reports: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.grey,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            reportProvider.loadReports(userProvider.currentUser!.userId);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final reports = snapshot.data ?? [];
                
                // Show empty state if no reports
                if (reports.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.description,
                          size: 64,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No reports yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => context.go('/patient/submit-report'),
                          child: const Text('Submit Your First Report'),
                        ),
                      ],
                    ),
                  );
                }
                
                final filteredReports = reports.where((report) {
                  final searchQuery = _searchController.text.toLowerCase();
                  final matchesSearch = searchQuery.isEmpty ||
                      report.title.toLowerCase().contains(searchQuery) ||
                      (report.doctorName?.toLowerCase().contains(searchQuery) ?? false) ||
                      (report.clinicName?.toLowerCase().contains(searchQuery) ?? false);
                  
                  final matchesCategory = _selectedCategory == 'All' ||
                      report.category == _selectedCategory;
                  
                  final matchesType = _selectedType == 'All' ||
                      report.fileType == _selectedType.toLowerCase();

                  return matchesSearch && matchesCategory && matchesType;
                }).toList();

                // Show empty state if all reports are filtered out
                if (filteredReports.isEmpty && reports.isNotEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppTheme.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No reports match your filters',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredReports.length,
                  itemBuilder: (context, index) {
                    final report = filteredReports[index];
                    return ReportCard(
                      report: report,
                      onTap: () => context.go('/patient/report/${report.reportId}'),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


