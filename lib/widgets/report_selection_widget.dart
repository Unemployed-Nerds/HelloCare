import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/report.dart';
import 'package:intl/intl.dart';

class ReportSelectionWidget extends StatefulWidget {
  final List<Report> reports;
  final Function(List<String> selectedReportIds) onGenerateSummary;

  const ReportSelectionWidget({
    super.key,
    required this.reports,
    required this.onGenerateSummary,
  });

  @override
  State<ReportSelectionWidget> createState() => _ReportSelectionWidgetState();
}

class _ReportSelectionWidgetState extends State<ReportSelectionWidget>
    with SingleTickerProviderStateMixin {
  final Set<String> _selectedReportIds = {};
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fabScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fabAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _updateSelection(String reportId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedReportIds.remove(reportId);
      } else {
        _selectedReportIds.add(reportId);
      }
    });

    if (_selectedReportIds.isNotEmpty) {
      _fabAnimationController.forward();
    } else {
      _fabAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGreen,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'AI Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Content
          Column(
            children: [
              // Compact Header
              _buildHeader(),
              // Reports List
              Expanded(
                child: widget.reports.isEmpty
                    ? _buildEmptyState()
                    : _buildReportsList(),
              ),
            ],
          ),
          // Floating Action Button
          _buildFloatingActionButton(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedReportIds.isEmpty
                ? 'Select reports to analyze'
                : '${_selectedReportIds.length} ${_selectedReportIds.length == 1 ? 'report' : 'reports'} selected',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 48,
            color: AppTheme.textSecondary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No Reports Available',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload reports to get started',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportsList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 90),
      itemCount: widget.reports.length,
      itemBuilder: (context, index) {
        final report = widget.reports[index];
        final isSelected = _selectedReportIds.contains(report.reportId);
        return _buildReportCard(report, isSelected, index);
      },
    );
  }

  Widget _buildReportCard(Report report, bool isSelected, int index) {
    final iconColor = report.fileType == 'pdf'
        ? AppTheme.errorRed
        : AppTheme.primaryGreen;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _updateSelection(report.reportId, isSelected),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.3),
                          AppTheme.primaryGreen.withOpacity(0.2),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.surfaceVariant.withOpacity(0.15),
                          AppTheme.surfaceVariant.withOpacity(0.1),
                        ],
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryGreen.withOpacity(0.6)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.primaryGreen.withOpacity(0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Selection Checkbox
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppTheme.primaryGreen
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.border,
                        width: isSelected ? 3 : 2.5,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryGreen.withOpacity(0.6),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check_rounded,
                            size: 18,
                            color: AppTheme.black,
                            weight: 3,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // File Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          iconColor,
                          iconColor.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      report.fileType == 'pdf'
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded,
                      color: AppTheme.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Report Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (report.category != null) ...[
                              Icon(
                                Icons.category_rounded,
                                size: 12,
                                color: AppTheme.textSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                report.category!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 12,
                              color: AppTheme.textSecondary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('MMM dd, yyyy').format(report.reportDate),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                        if (report.doctorName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_rounded,
                                size: 12,
                                color: AppTheme.textSecondary.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Dr. ${report.doctorName}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
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

  Widget _buildFloatingActionButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ScaleTransition(
        scale: _fabScaleAnimation,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _selectedReportIds.isNotEmpty ? 1.0 : 0.0,
          child: IgnorePointer(
            ignoring: _selectedReportIds.isEmpty,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryGreen,
                    AppTheme.primaryGreenDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    widget.onGenerateSummary(_selectedReportIds.toList());
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          color: AppTheme.black,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _selectedReportIds.length > 1
                              ? 'Generate Comparison'
                              : 'Generate Summary',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.black,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
