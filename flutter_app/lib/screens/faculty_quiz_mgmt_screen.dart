import 'dart:io';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel_pkg;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';

class FacultyQuizMgmtScreen extends StatefulWidget {
  const FacultyQuizMgmtScreen({super.key});

  @override
  State<FacultyQuizMgmtScreen> createState() => _FacultyQuizMgmtScreenState();
}

class _FacultyQuizMgmtScreenState extends State<FacultyQuizMgmtScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _kbArticlesFuture;
  String? _selectedKbArticleId;
  double _numQuestions = 5;
  DateTime? _validFrom;
  DateTime? _validUntil;
  int? _timeLimitMins;
  String? _targetYear = 'All';
  int? _maxAttempts;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _kbArticlesFuture = _fetchKbArticles();
  }

  Future<List<dynamic>> _fetchKbArticles() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    final response = await _apiService.get('/api/kb', requireAuth: true);
    return (response as List<dynamic>)
        .where((article) => article['author_id'] == userId)
        .toList();
  }

  void _generateQuiz() async {
    if (_selectedKbArticleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Knowledge Base Article')),
      );
      return;
    }

    // Show a non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        );
      },
    );

    try {
      final quizProvider = context.read<QuizProvider>();
      final newQuiz = await quizProvider.generateQuizFromKB(
        _selectedKbArticleId!,
        numQuestions: _numQuestions.toInt(),
        validFrom: _validFrom,
        validUntil: _validUntil,
        timeLimitMins: _timeLimitMins,
        targetYear: _targetYear,
        maxAttempts: _maxAttempts,
        isActive: _isActive,
      );

      if (mounted) {
        // Close the loading dialog
        Navigator.of(context, rootNavigator: true).pop();

        if (newQuiz != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Success! Generated quiz: ${newQuiz.title}'),
            backgroundColor: const Color(0xFF10B981),
          ));
          setState(() {
            _selectedKbArticleId = null;
            _numQuestions = 5;
          });
          // Close the bottom sheet modal
          Navigator.of(context).pop();
          // Redirect to the quizzes home page
          context.go('/app/quizzes');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to generate quiz: ${quizProvider.error}'),
            backgroundColor: AppTheme.errorColor,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Make sure dialog closes on unexpected errors
      }
    }
  }

  void _showGenerateQuizModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Color(0xFF10B981)),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Generate AI Quiz',
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                'Create an adaptive assessment from a Knowledge Base article.',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    FutureBuilder<List<dynamic>>(
                      future: _kbArticlesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Failed to load Knowledge Base articles.',
                                style: TextStyle(
                                    color:
                                        AppTheme.errorColor.withOpacity(0.8)),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setModalState(() {
                                    _kbArticlesFuture = _fetchKbArticles();
                                  });
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.white.withOpacity(0.1),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        }
                        final articles = snapshot.data ?? [];
                        if (articles.isEmpty) {
                          return const Text(
                            'No KB articles found. Please create one first.',
                            style: TextStyle(color: AppTheme.errorColor),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: _selectedKbArticleId,
                          dropdownColor: const Color(0xFF1E293B),
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Select KB Article',
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
                            filled: true,
                            fillColor: Colors.black.withOpacity(0.2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          items: articles.map((article) {
                            return DropdownMenuItem<String>(
                              value: article['id'].toString(),
                              child: Text(
                                article['title'] ?? 'Untitled',
                                style: const TextStyle(color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setModalState(() {
                              _selectedKbArticleId = val;
                            });
                            setState(() {
                              _selectedKbArticleId = val;
                            });
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Number of Questions: ${_numQuestions.toInt()}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Slider(
                      value: _numQuestions,
                      min: 5,
                      max: 10,
                      divisions: 5,
                      activeColor: const Color(0xFF10B981),
                      inactiveColor: Colors.white.withOpacity(0.1),
                      onChanged: (val) {
                        setModalState(() {
                          _numQuestions = val;
                        });
                        setState(() {
                          _numQuestions = val;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Valid Dates
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Valid Dates: ${_validFrom != null && _validUntil != null ? "${_validFrom!.day}/${_validFrom!.month}/${_validFrom!.year} - ${_validUntil!.day}/${_validUntil!.month}/${_validUntil!.year}" : "Not Set"}',
                            style:
                                TextStyle(color: Colors.white.withOpacity(0.8)),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime.now(),
                              lastDate:
                                  DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setModalState(() {
                                _validFrom = picked.start;
                                _validUntil = picked.end;
                              });
                              setState(() {
                                _validFrom = picked.start;
                                _validUntil = picked.end;
                              });
                            }
                          },
                          child: const Text('Set Dates',
                              style: TextStyle(color: Color(0xFF10B981))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Time Limit and Year
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Duration (mins)',
                              labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                            onChanged: (val) {
                              final parsed = int.tryParse(val);
                              setModalState(() => _timeLimitMins = parsed);
                              setState(() => _timeLimitMins = parsed);
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _targetYear,
                            dropdownColor: const Color(0xFF1E293B),
                            decoration: InputDecoration(
                              labelText: 'Target Year',
                              labelStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.5)),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.2),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none),
                            ),
                            items: ['All', '1', '2', '3', '4']
                                .map((y) => DropdownMenuItem(
                                    value: y,
                                    child: Text(
                                        y == 'All' ? 'All Years' : 'Year $y',
                                        style: const TextStyle(
                                            color: Colors.white))))
                                .toList(),
                            onChanged: (val) {
                              setModalState(() => _targetYear = val);
                              setState(() => _targetYear = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Max Attempts
                    TextFormField(
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Max Attempts (Leave blank for unlimited)',
                        labelStyle:
                            TextStyle(color: Colors.white.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.2),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      onChanged: (val) {
                        final parsed = int.tryParse(val);
                        setModalState(() => _maxAttempts = parsed);
                        setState(() => _maxAttempts = parsed);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Is Active Switch
                    SwitchListTile(
                      title: Text('Active / Visible to Students',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.8))),
                      value: _isActive,
                      activeColor: const Color(0xFF10B981),
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) {
                        setModalState(() => _isActive = val);
                        setState(() => _isActive = val);
                      },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _generateQuiz,
                        icon: const Icon(Icons.psychology),
                        label: const Text('Generate and Save Quiz'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppTheme.backgroundGradient,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Create Quiz',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _buildActionCard(
                    title: 'AI Gen',
                    subtitle: 'Generate from Knowledge Base Article',
                    icon: Icons.auto_awesome,
                    color: Colors.greenAccent,
                    onTap: _showGenerateQuizModal,
                    isFullWidth: true,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildActionCard(
                    title: 'Import',
                    subtitle: 'Upload Excel/CSV file',
                    icon: Icons.upload_file,
                    color: Colors.lightBlueAccent,
                    onTap: _importExcelQuiz, // Connect the new logic!
                    isFullWidth: true,
                    trailingWidget: IconButton(
                      icon: Icon(Icons.info_outline_rounded,
                          color: Colors.lightBlueAccent.withOpacity(0.8)),
                      onPressed: _showImportInfoDialog,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: _buildActionCard(
                    title: 'Manual Creation',
                    subtitle:
                        'Build a quiz from scratch using the form builder.',
                    icon: Icons.edit_note,
                    color: Colors.orangeAccent,
                    isFullWidth: true,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Manual Builder coming soon!')));
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
    Widget? trailingWidget,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.8), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 36),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            color: color)),
                    const SizedBox(height: 8),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                            height: 1.3)),
                  ],
                ),
              ),
              trailingWidget ??
                  Icon(Icons.arrow_forward_ios_rounded,
                      color: color.withOpacity(0.5), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _importExcelQuiz() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        File file = File(filePath);

        // Show uploading snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white)),
                  SizedBox(width: 15),
                  Text('Uploading and parsing quizzes...'),
                ],
              ),
              duration: Duration(seconds: 10), // Keep open during upload
            ),
          );
        }

        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = await authProvider.getToken();
        if (token == null) throw Exception("User is not authenticated");

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('${ApiService().baseUrl}/quizzes/import'),
        );

        request.headers.addAll({
          'Authorization': 'Bearer $token',
        });

        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
          ),
        );

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);

        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar(); // Hide loading
        }

        if (response.statusCode == 201) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Quizzes imported successfully! They are saved as drafted (Inactive).'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 4),
              ),
            );
            // Refresh quizzes
            Provider.of<QuizProvider>(context, listen: false).loadQuizzes();
          }
        } else {
          throw Exception('Upload failed: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .hideCurrentSnackBar(); // Hide loading just in case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error importing file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _showImportInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
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
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 48, color: Colors.lightBlueAccent),
              const SizedBox(height: 16),
              const Text(
                'Excel/CSV Import',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Mass import your quizzes smoothly! Download the simplified template below. Each row represents a single question. Group questions into the same quiz by using the exact same "quiz_title"!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _downloadSampleDataset();
                },
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Download Sample Dataset'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.lightBlueAccent,
                  side: const BorderSide(color: Colors.lightBlueAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Got it',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadSampleDataset() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/sample_quizzes_dataset.xlsx');

      var excel = excel_pkg.Excel.createExcel();
      excel_pkg.Sheet sheetObject = excel['Sheet1'];

      // Add Headers
      sheetObject.appendRow([
        excel_pkg.TextCellValue('quiz_title'),
        excel_pkg.TextCellValue('time_limit_mins'),
        excel_pkg.TextCellValue('max_attempts'),
        excel_pkg.TextCellValue('valid_from (YYYY-MM-DD)'),
        excel_pkg.TextCellValue('valid_until (YYYY-MM-DD)'),
        excel_pkg.TextCellValue('target_year'),
        excel_pkg.TextCellValue('target_department'),
        excel_pkg.TextCellValue('question_text'),
        excel_pkg.TextCellValue('option_a'),
        excel_pkg.TextCellValue('option_b'),
        excel_pkg.TextCellValue('option_c'),
        excel_pkg.TextCellValue('option_d'),
        excel_pkg.TextCellValue('correct_answer'),
        excel_pkg.TextCellValue('explanation'),
      ]);

      // Row 1 - Quiz 1, Q1
      sheetObject.appendRow([
        excel_pkg.TextCellValue('Introduction to Python'),
        excel_pkg.IntCellValue(10),
        excel_pkg.IntCellValue(2),
        excel_pkg.TextCellValue('2026-03-01'),
        excel_pkg.TextCellValue('2026-03-31'),
        excel_pkg.TextCellValue('1'),
        excel_pkg.TextCellValue('CSE'),
        excel_pkg.TextCellValue('What makes Python easy to learn?'),
        excel_pkg.TextCellValue('Complex library'),
        excel_pkg.TextCellValue('Clear syntax'),
        excel_pkg.TextCellValue('Low-level code'),
        excel_pkg.TextCellValue('Rigid structure'),
        excel_pkg.TextCellValue('Clear syntax'),
        excel_pkg.TextCellValue(
            'Python\'s clear syntax and readability simplify learning.'),
      ]);

      // Row 2 - Quiz 1, Q2
      sheetObject.appendRow([
        excel_pkg.TextCellValue('Introduction to Python'),
        excel_pkg.IntCellValue(10), // Duplicated for the same quiz
        excel_pkg.IntCellValue(2),
        excel_pkg.TextCellValue('2026-03-01'),
        excel_pkg.TextCellValue('2026-03-31'),
        excel_pkg.TextCellValue('1'),
        excel_pkg.TextCellValue('CSE'),
        excel_pkg.TextCellValue('Which is a key application area for Python?'),
        excel_pkg.TextCellValue('Embedded systems'),
        excel_pkg.TextCellValue('Low-level hardware'),
        excel_pkg.TextCellValue('Network routing'),
        excel_pkg.TextCellValue('Web development'),
        excel_pkg.TextCellValue('Web development'),
        excel_pkg.TextCellValue(
            'Python is widely used in web development and data science.'),
      ]);

      // Row 3 - Quiz 2, Q1
      sheetObject.appendRow([
        excel_pkg.TextCellValue('NoSQL Databases'),
        excel_pkg.IntCellValue(15),
        excel_pkg.IntCellValue(3),
        excel_pkg.TextCellValue('2026-03-05'),
        excel_pkg.TextCellValue('2026-04-30'),
        excel_pkg.TextCellValue('3'),
        excel_pkg.TextCellValue('IT'),
        excel_pkg.TextCellValue('NoSQL handles what type of data best?'),
        excel_pkg.TextCellValue('Relational'),
        excel_pkg.TextCellValue('Tabular'),
        excel_pkg.TextCellValue('Structured'),
        excel_pkg.TextCellValue('Unstructured'),
        excel_pkg.TextCellValue('Unstructured'),
        excel_pkg.TextCellValue(
            'NoSQL databases optimally handle unstructured or semi-structured data.'),
      ]);

      List<int>? fileBytes = excel.save();
      if (fileBytes != null) {
        await file.writeAsBytes(fileBytes);
      }

      if (mounted) {
        final params = SaveFileDialogParams(sourceFilePath: file.path);
        final finalPath = await FlutterFileDialog.saveFile(params: params);

        if (finalPath != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sample dataset downloaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to download sample: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
