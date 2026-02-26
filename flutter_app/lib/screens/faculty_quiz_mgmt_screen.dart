import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
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
  String? _targetYear;
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
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Failed to load Knowledge Base articles.',
                              style: TextStyle(
                                  color: AppTheme.errorColor.withOpacity(0.8)),
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
                                backgroundColor: Colors.white.withOpacity(0.1),
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
                            labelStyle:
                                TextStyle(color: Colors.white.withOpacity(0.5)),
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

                  // Is Active Switch
                  SwitchListTile(
                    title: Text('Active / Visible to Students',
                        style: TextStyle(color: Colors.white.withOpacity(0.8))),
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
            'Quiz Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Action Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildActionCard(
                        title: 'AI Gen',
                        subtitle: 'From KB Article',
                        icon: Icons.auto_awesome,
                        color: const Color(0xFF10B981),
                        onTap: _showGenerateQuizModal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionCard(
                        title: 'Import',
                        subtitle: 'From Excel/CSV',
                        icon: Icons.upload_file,
                        color: AppTheme.primaryColor,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Excel Import coming soon!')));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  title: 'Manual Creation',
                  subtitle: 'Build a quiz from scratch using the form builder.',
                  icon: Icons.edit_note,
                  color: const Color(0xFFF59E0B),
                  isFullWidth: true,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Manual Builder coming soon!')));
                  },
                ),

                const SizedBox(height: 32),

                const Row(
                  children: [
                    Icon(Icons.analytics_outlined,
                        color: AppTheme.primaryLight),
                    SizedBox(width: 8),
                    Text(
                      'Class Insights & Revision',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.insert_chart_outlined,
                            size: 64, color: Colors.white.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        Text(
                          'No class data yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Once students take quizzes, AI revision topics will appear here.',
                          textAlign: TextAlign.center,
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
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

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: isFullWidth
              ? Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.6))),
                        ],
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(height: 16),
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6))),
                  ],
                ),
        ),
      ),
    );
  }
}
