import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../utils/constants.dart';
import '../utils/permissions.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _articles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get(AppConstants.kbEndpoint);
      if (mounted) {
        setState(() {
          _articles = response as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading articles: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _loadArticles();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final response = await _apiService
          .get('${AppConstants.kbEndpoint}/search', params: {'query': query});
      if (mounted) {
        setState(() {
          _articles = response as List;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _downloadSampleExcel() async {
    try {
      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      List<String> headers = ['title', 'category', 'content'];
      sheetObject
          .appendRow(headers.map((e) => excel_pkg.TextCellValue(e)).toList());

      // Add Sample Rows
      final sampleData = [
        [
          'Campus Map Navigation',
          'Facilities',
          'To navigate the campus, open the map feature on the bottom right corner of the dashboard. This uses Google Maps to provide directions.'
        ],
        [
          'Exam Attendance Requirements',
          'Academic',
          'Students must maintain a minimum of 75% attendance in total to be eligible for the semester-end examinations.'
        ],
        [
          'Library Borrowing Rules',
          'Policy',
          'You may borrow up to 3 books at a time. The standard borrowing duration is 14 days, with an option to renew online once.'
        ],
      ];

      for (var row in sampleData) {
        sheetObject
            .appendRow(row.map((e) => excel_pkg.TextCellValue(e)).toList());
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_knowledge_base.xlsx');
      await file.writeAsBytes(excel.encode()!);

      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Template saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importCSV() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        final file = File(result.files.single.path!);

        final response = await _apiService.postMultipart(
          '${AppConstants.kbEndpoint}/import',
          {},
          file,
          fileFieldName: 'file',
        );

        setState(() => _isLoading = false);

        if (mounted) {
          final count = response['count'] ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully imported $count articles!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadArticles();
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            title: const Text('Import Failed',
                style: TextStyle(color: Colors.white)),
            content: Text(e.toString().replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'))
            ],
          ),
        );
      }
    }
  }

  Future<void> _showArticleDialog(
      Map<String, dynamic> article, bool canModify) async {
    final categoryColor = _getCategoryColor(article['category'] ?? 'General');

    await showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                article['title'],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Text(
                  article['category'] ?? 'General',
                  style: TextStyle(
                      fontSize: 12,
                      color: categoryColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                article['content'],
                style: const TextStyle(
                    color: Colors.white70, fontSize: 15, height: 1.5),
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (canModify) ...[
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: AppTheme.errorColor),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              width: double.infinity,
                              constraints: const BoxConstraints(maxWidth: 400),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF1E293B),
                                    Color(0xFF0F172A)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.1)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.errorColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.delete_rounded,
                                        size: 32, color: AppTheme.errorColor),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Delete Article',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Are you sure you want to delete this article?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white70,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                          ),
                                          child: const Text('Cancel'),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                AppTheme.errorColor,
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                          ),
                                          child: const Text('Delete',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );

                        if (confirm == true) {
                          try {
                            await _apiService.delete(
                                '${AppConstants.kbEndpoint}/${article['id']}');
                            if (mounted) {
                              Navigator.pop(context);
                              _loadArticles();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error deleting article: $e')),
                              );
                            }
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: AppTheme.primaryColor),
                      onPressed: () {
                        Navigator.pop(context);
                        _showAddEditArticleDialog(article: article);
                      },
                    ),
                    const Spacer(),
                  ],
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddEditArticleDialog(
      {Map<String, dynamic>? article}) async {
    final isEdit = article != null;
    final titleController = TextEditingController(text: article?['title']);
    final contentController = TextEditingController(text: article?['content']);
    String category = article?['category'] ?? 'General';
    if (!['General', 'Policy', 'Academic', 'Facilities', 'Handbook']
        .contains(category)) {
      category = 'General';
    }

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? 'Edit Article' : 'New Knowledge Article',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildDialogTextField(titleController, 'Title',
                      icon: Icons.title_rounded),
                  const SizedBox(height: 16),
                  _buildDialogTextField(contentController, 'Content',
                      maxLines: 8, icon: Icons.article_rounded),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: 'Category',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        prefixIcon: Icon(Icons.category_rounded,
                            color: Colors.white.withOpacity(0.7), size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.1))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05)),
                    items: [
                      'General',
                      'Policy',
                      'Academic',
                      'Facilities',
                      'Handbook'
                    ]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (val) => setDialogState(() => category = val!),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.white70),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (titleController.text.isEmpty ||
                              contentController.text.isEmpty) {
                            return;
                          }

                          final data = {
                            'title': titleController.text,
                            'content': contentController.text,
                            'category': category,
                          };

                          try {
                            if (isEdit) {
                              await _apiService.put(
                                  '${AppConstants.kbEndpoint}/${article['id']}',
                                  data);
                            } else {
                              await _apiService.post(
                                  AppConstants.kbEndpoint, data);
                            }

                            if (mounted) {
                              Navigator.pop(context);
                              _loadArticles();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(isEdit
                                        ? 'Article updated'
                                        : 'Article published')),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text(isEdit ? 'Save' : 'Publish',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              const Icon(
                Icons.article_rounded,
                size: 48,
                color: AppTheme.primaryLight,
              ),
              const SizedBox(height: 16),
              const Text(
                'Import Guidelines',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To import articles, please use an Excel (.xlsx) or CSV (.csv) file with the following headers:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• title: The title of the article', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                    Text('• category: General, Policy, Academic, Facilities, or Handbook', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                    Text('• content: The body text of the article', style: TextStyle(color: Colors.white, fontSize: 13, height: 1.5)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _downloadSampleExcel();
                  },
                  icon: const Icon(Icons.table_view_rounded, size: 18),
                  label: const Text('Download Sample Excel'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.greenAccent,
                    side: const BorderSide(color: Colors.greenAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.edit_document, color: AppTheme.primaryLight),
                ),
                title: const Text('Create Manually', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Write a new article from scratch', style: TextStyle(color: Colors.white54, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _showAddEditArticleDialog();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.upload_file_rounded, color: Colors.greenAccent),
                ),
                title: const Text('Import via Excel/CSV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: const Text('Upload multiple articles at once', style: TextStyle(color: Colors.white54, fontSize: 13)),
                onTap: () {
                  Navigator.pop(context);
                  _importCSV();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String label,
      {int maxLines = 1, IconData? icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.white.withOpacity(0.7), size: 20)
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final permissions = AppPermissions(authProvider);
    final canAdd = permissions.canManageKB;
    // Check role to determine layout
    final isFaculty = (authProvider.userRole ?? '').toLowerCase() == 'faculty';
    final currentUserId = authProvider.user?.id;

    // Split articles if faculty
    List<dynamic> myArticles = [];
    List<dynamic> otherArticles = [];

    if (isFaculty && currentUserId != null) {
      // Ensure strict type checking and null safety
      myArticles = _articles.where((a) {
        final authorId = a['author_id'];
        return authorId != null && authorId.toString() == currentUserId;
      }).toList();

      otherArticles = _articles.where((a) {
        final authorId = a['author_id'];
        return authorId == null || authorId.toString() != currentUserId;
      }).toList();
    } else {
      otherArticles = _articles; // Everyone else calls it 'all' effectively
    }

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow gradient from Container
      floatingActionButton: canAdd
          ? FloatingActionButton(
              onPressed: _showAddOptions,
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Removed redundant "University Handbook" text
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search knowledge base...',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white54),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.send, color: AppTheme.primaryLight),
                            onPressed: _handleSearch,
                          ),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05), // Glassmorphism Search
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        ),
                        onSubmitted: (_) => _handleSearch(),
                      ),
                    ),
                    if (canAdd) ...[
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.info_outline_rounded, color: AppTheme.primaryLight),
                          onPressed: _showInfoDialog,
                          tooltip: 'Import Guidelines',
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Faculty Section: My Articles
                              if (isFaculty) ...[
                                if (myArticles.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.only(bottom: 12),
                                    child: Text('My Articles',
                                        style: TextStyle(
                                            color: AppTheme.primaryLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ),
                                  ...myArticles
                                      .map((article) => _buildArticleCard(
                                          article, true, true))
                                      ,
                                  const SizedBox(height: 24),
                                ],
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text('All Articles',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ),
                              ],

                              if (otherArticles.isEmpty && myArticles.isEmpty)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 100),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.menu_book_rounded,
                                            size: 64,
                                            color:
                                                Colors.white.withOpacity(0.2)),
                                        const SizedBox(height: 16),
                                        Text('No articles found.',
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.5))),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...otherArticles
                                    .map((article) => _buildArticleCard(
                                        article, false, false))
                                    ,

                              const SizedBox(
                                  height: 80), // Bottom padding for FAB
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'policy':
        return const Color(0xFFEF4444); // Red
      case 'academic':
        return const Color(0xFF3B82F6); // Blue
      case 'facilities':
        return const Color(0xFF10B981); // Emerald
      case 'handbook':
        return const Color(0xFFEAB308); // Yellow
      default:
        return const Color(0xFF8B5CF6); // Violet (General)
    }
  }

  Widget _buildArticleCard(
      Map<String, dynamic> article, bool isOwner, bool canModify) {
    // Override canModify if Admin
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isAdmin = auth.userRole == 'admin';
    final effectiveCanModify = canModify || isAdmin;
    final categoryColor = _getCategoryColor(article['category'] ?? 'General');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          _showArticleDialog(article, effectiveCanModify);
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05), // Glassmorphism Standard
            borderRadius: BorderRadius.circular(20),
            border: isOwner
                ? Border.all(
                    color: AppTheme.primaryColor
                        .withOpacity(0.5)) // Highlight owned
                : Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: categoryColor.withOpacity(0.3)),
                ),
                child: Icon(Icons.menu_book_rounded,
                    color: categoryColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(article['title'],
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(
                      article['content'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.6), fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // removed edit icon as requested
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }
}
