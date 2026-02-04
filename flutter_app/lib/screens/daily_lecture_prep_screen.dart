import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../config/theme.dart';
import '../widgets/pulse_icon.dart';

class DailyLecturePrepScreen extends StatefulWidget {
  const DailyLecturePrepScreen({super.key});

  @override
  State<DailyLecturePrepScreen> createState() => _DailyLecturePrepScreenState();
}

class _DailyLecturePrepScreenState extends State<DailyLecturePrepScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  late TabController _tabController;

  // Form State
  int _selectedYear = 4; // Default
  String? _selectedSubject;
  List<Map<String, dynamic>> _availableSubjects = [];
  bool _isLoadingSubjects = false;

  bool _isRevisionMode = false; // False = Daily, True = Revision
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _durationController =
      TextEditingController(text: '50');
  String _selectedTone = 'Engaging';

  // Output State
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedPlan;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _topicController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  String _stripEmojis(String text) {
    return text.replaceAll(
        RegExp(
            r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2B50}]',
            unicode: true),
        '');
  }

  Future<void> _downloadPdf() async {
    if (_generatedPlan == null) return;

    try {
      final pdf = pw.Document();
      final title = _stripEmojis(_generatedPlan!['title'] ?? 'Lesson Plan');
      final hook = _stripEmojis(_generatedPlan!['hook_analogy'] ?? '');
      final theory = (_generatedPlan!['core_theory_points'] as List<dynamic>?)
              ?.map((e) => _stripEmojis(e.toString()))
              .toList() ??
          [];
      final timeline = (_generatedPlan!['timeline'] as List<dynamic>?) ?? [];
      final resources = (_generatedPlan!['resources'] as List<dynamic>?) ?? [];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 10),
              child: pw.Text(
                'AI Lecture Co-Pilot - Empowering Educators',
                style:
                    const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Text(DateTime.now().toString().split(' ')[0],
                        style: const pw.TextStyle(
                            fontSize: 12, color: PdfColors.grey)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                  'Subject: $_selectedSubject | Topic: ${_topicController.text}',
                  style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              if (hook.isNotEmpty) ...[
                pw.Text('THE HOOK',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, color: PdfColors.blue)),
                pw.SizedBox(height: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Text(hook,
                      style: pw.TextStyle(fontStyle: pw.FontStyle.italic)),
                ),
                pw.SizedBox(height: 20),
              ],
              if (theory.isNotEmpty) ...[
                pw.Text('CORE THEORY',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 5),
                ...theory.map((p) => pw.Bullet(text: p)),
                pw.SizedBox(height: 20),
              ],
              pw.Text('MINUTE-BY-MINUTE SCRIPT',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1), // Time
                  1: const pw.FlexColumnWidth(2), // Section
                  2: const pw.FlexColumnWidth(4), // Script
                },
                children: [
                  pw.TableRow(
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Time',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Section',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(5),
                          child: pw.Text('Script Notes',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...timeline.map((item) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(_stripEmojis(item['time'] ?? ''))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child:
                                pw.Text(_stripEmojis(item['section'] ?? ''))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(5),
                            child: pw.Text(
                                _stripEmojis(item['script_notes'] ?? ''))),
                      ],
                    );
                  }),
                ],
              ),
              if (resources.isNotEmpty) ...[
                pw.SizedBox(height: 20),
                pw.Text('VALID RESOURCES',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                ...resources.map((res) {
                  final title = _stripEmojis(res['title'] ?? 'Resource');
                  final type = res['type'] ?? 'Article';
                  // Generate search URL as fallback since we don't store direct URLs
                  final query = Uri.encodeComponent(title);
                  final url = type.toString().toLowerCase().contains('video')
                      ? 'https://www.youtube.com/results?search_query=$query'
                      : 'https://www.google.com/search?q=$query';

                  return pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 5),
                      child: pw.UrlLink(
                          child: pw.Text('• $title ($type)',
                              style: const pw.TextStyle(
                                  color: PdfColors.blue,
                                  decoration: pw.TextDecoration.underline)),
                          destination: url));
                }),
              ],
            ];
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: '${_selectedSubject}_${_topicController.text}_Plan.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('PDF Error: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      // Get department from user profile
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final department = authProvider.user?.department ?? '';

      final response = await _apiService.get(
          '/api/lectures/subjects?year=$_selectedYear&department=$department');

      if (response['subjects'] != null) {
        setState(() {
          _availableSubjects =
              List<Map<String, dynamic>>.from(response['subjects']);
          if (_availableSubjects.isNotEmpty) {
            // Auto-select first if available
            _selectedSubject = _availableSubjects.first['name'];
            _durationController.text =
                _availableSubjects.first['duration'].toString();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingSubjects = false);
    }
  }

  void _onSubjectChanged(String? newValue) {
    setState(() {
      _selectedSubject = newValue;
      // Auto-update duration
      final subjectData = _availableSubjects.firstWhere(
          (element) => element['name'] == newValue,
          orElse: () => {});
      if (subjectData.isNotEmpty) {
        _durationController.text = subjectData['duration'].toString();
      }
    });
  }

  Future<void> _generatePlan() async {
    if (_isGenerating) return;

    // Validation logic
    if (_generatedPlan == null) {
      // Initial generation: Form is visible, use standard validation
      if (_formKey.currentState?.validate() != true) return;
    } else {
      // Regeneration: Form is hidden, check controller directly
      if (_topicController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Topic is required')));
        return;
      }
    }

    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a subject')));
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final payload = {
        'subject': _selectedSubject,
        'topic': _topicController.text,
        'year': _selectedYear,
        'tone': _selectedTone,
        'duration': int.tryParse(_durationController.text) ?? 50,
        'classType': _isRevisionMode ? 'revision' : 'daily'
      };

      final response =
          await _apiService.post('/api/lectures/generate', payload);

      if (response != null &&
          response is Map &&
          response.containsKey('error')) {
        throw Exception(response['error']);
      }

      setState(() {
        _generatedPlan = response;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to generate plan: $e')));
      }
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (_generatedPlan != null) _buildResultToolbar(),
              Expanded(
                child: _isGenerating
                    ? _buildLoadingState()
                    : _generatedPlan == null
                        ? _buildEmptyState()
                        : _buildPlanView(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultToolbar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => setState(() => _generatedPlan = null),
            tooltip: 'Back to Inputs',
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.download_rounded, color: Colors.white),
                onPressed: _downloadPdf,
                tooltip: 'Download PDF',
              ),
              IconButton(
                icon: const Icon(Icons.autorenew_rounded, color: Colors.white),
                onPressed: _generatePlan,
                tooltip: 'Regenerate Plan',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            'Analyzing subject & pedagogy...',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            'Crafting your expert teaching script 🎓',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
          horizontal: 24, vertical: 12), // Increased to breathe
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20), // Standard padding
            decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  )
                ]),
            child: const PulseIcon(
              isSelected: true,
              child: Icon(
                Icons.auto_awesome_rounded,
                size: 52, // Balanced size
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 16), // Increased spacing
          Text(
            'Create Your Lesson Masterpiece',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24, // Restored prominence
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8), // Standard spacing
          Text(
            'Generate a minute-by-minute teaching script, real-world analogies, and valid resources.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14, // Readable subtitle
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24), // Increased separation for form
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Form(
      key: _formKey,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 20), // Increased vertical padding
        decoration: BoxDecoration(
          color: AppTheme.cardColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            // Row 1: Year & Subject
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Year'),
                    items: [1, 2, 3, 4]
                        .map((y) =>
                            DropdownMenuItem(value: y, child: Text('Year $y')))
                        .toList(),
                    onChanged: _isLoadingSubjects
                        ? null
                        : (val) {
                            setState(() => _selectedYear = val!);
                            _fetchSubjects();
                          },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSubject,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration('Subject'),
                    items: _availableSubjects
                        .map((s) => DropdownMenuItem<String>(
                              value: s['name'],
                              child: Text(s['name'],
                                  overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: _isLoadingSubjects ? null : _onSubjectChanged,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing

            // Row 2: Topic (Full Width)
            TextFormField(
              controller: _topicController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('What topic are we covering?'),
              validator: (v) => v!.isEmpty ? 'Topic is required' : null,
            ),
            const SizedBox(height: 16), // Spacing

            // Row 3: Class Type & Duration

            // Row 3: Class Type & Duration
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 48, // Reduced from 52
                    padding: const EdgeInsets.all(4), // Padding for the track
                    decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius:
                            BorderRadius.circular(16), // Increased radius
                        border: Border.all(color: Colors.white12)),
                    child: Row(
                      children: [
                        _buildToggleOption(false, 'Lecture'),
                        _buildToggleOption(true, 'Revision'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height:
                        48, // Reduced from 52 (implicit by contentPadding but explicit height helps alignment)
                    child: TextFormField(
                      controller: _durationController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Mins'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16), // Spacing

            // Row 4: Tone Selector
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Select Lecture Tone',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13, // Slightly increased
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12), // Spacing
            Container(
              padding: const EdgeInsets.all(6), // Balanced padding
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _buildToneOption('Formal', Icons.school_rounded,
                          const Color(0xFF10B981))),
                  Expanded(
                      child: _buildToneOption(
                          'Engaging',
                          Icons.rocket_launch_rounded,
                          const Color(0xFFF59E0B))),
                  Expanded(
                      child: _buildToneOption('Storytelling',
                          Icons.auto_stories_rounded, const Color(0xFFEF4444))),
                ],
              ),
            ),
            const SizedBox(height: 16), // Reduced from 20

            // Row 5: Generate Button
            SizedBox(
              width: double.infinity,
              height: 48, // Reduced from 52
              child: ElevatedButton(
                onPressed: _isGenerating ? null : _generatePlan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                ),
                child: const Text('Generate Lesson Plan',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToneOption(String tone, IconData icon, Color color) {
    final isSelected = _selectedTone == tone;
    return GestureDetector(
      onTap: () => setState(() => _selectedTone = tone),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            PulseIcon(
              isSelected: isSelected,
              child: Icon(
                icon,
                color: isSelected
                    ? color
                    : Colors.white.withValues(alpha: 0.6), // Increased from 0.4
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tone,
              style: TextStyle(
                color: isSelected
                    ? color
                    : Colors.white.withValues(alpha: 0.6), // Increased from 0.4
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleOption(bool isRev, String label) {
    final isSelected = _isRevisionMode == isRev;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isRevisionMode = isRev),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius:
                BorderRadius.circular(12), // Match parent radius minus padding
          ),
          alignment: Alignment.center,
          child: Text(label,
              style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white70, // Brighter text
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.7)), // Increased from 0.5
      filled: true,
      fillColor: Colors.black26,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 12), // Reduced vertical padding
    );
  }

  Widget _buildPlanView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 20), // Standard horizontal padding
          child: Container(
            height: 48, // Fixed height for consistency
            padding: const EdgeInsets.all(1), // Minimal padding for the track
            decoration: BoxDecoration(
              color: Colors.black26, // Darker track like the other toggle
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab, // Ensure it fills the tab
              indicator: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius:
                    BorderRadius.circular(14), // Match parent radius - padding
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.zero, // Remove label padding to stretch
              labelStyle:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.description_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Script')
                    ])),
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.link_rounded, size: 16),
                      SizedBox(width: 8),
                      Text('Links')
                    ])),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildScriptTab(),
              _buildResourcesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScriptTab() {
    final title = _generatedPlan?['title'] ?? 'Lecture Plan';
    final hook = _generatedPlan?['hook_analogy'] ?? '';
    final theory = _generatedPlan?['core_theory_points'] as List<dynamic>?;
    final timeline = _generatedPlan?['timeline'] as List<dynamic>?;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expert Lecture Plan • ${_topicController.text}',
                  style: TextStyle(
                      color: Colors.white
                          .withValues(alpha: 0.8)), // Increased from 0.6
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (hook.isNotEmpty) ...[
            _buildSectionHeader('The Hook', Icons.anchor_rounded),
            const SizedBox(height: 12),
            _buildGlassCard(
              child: Text(
                hook,
                style: const TextStyle(
                    fontSize: 15, height: 1.5, fontStyle: FontStyle.italic),
              ),
            ),
            const SizedBox(height: 24),
          ],
          if (theory != null && theory.isNotEmpty) ...[
            _buildSectionHeader('Core Theory', Icons.menu_book_rounded),
            const SizedBox(height: 12),
            _buildGlassCard(
              child: Column(
                children: theory
                    .map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ',
                                  style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 20)),
                              Expanded(child: Text(p.toString())),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Class Timeline', Icons.timer_rounded),
          const SizedBox(height: 12),
          if (timeline != null)
            ...timeline.asMap().entries.map((entry) {
              return _buildTimelineItem(
                  entry.value, entry.key == timeline.length - 1);
            }),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor.withValues(alpha: 0.6), // Increased opacity
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildGlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align to top
                      children: [
                        Expanded(
                          // Fix overflow
                          child: Text(item['section'] ?? '',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Larger Title
                                  color: AppTheme.primaryColor)),
                        ),
                        const SizedBox(width: 8),
                        Text(item['time'] ?? '',
                            style: const TextStyle(
                                color: Colors.white70, // More vibrant
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['script_notes'] ?? '',
                      style: const TextStyle(fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    final resources = _generatedPlan?['resources'] as List<dynamic>?;

    if (resources == null || resources.isEmpty) {
      return const Center(child: Text('No resources found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: resources.length,
      itemBuilder: (context, index) {
        final res = resources[index];
        final type = res['type'] ?? 'Video';
        final isVideo = type.toString().toLowerCase().contains('video');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            tileColor: AppTheme.cardColor.withValues(alpha: 0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isVideo
                    ? Colors.red.withValues(alpha: 0.1)
                    : Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isVideo
                    ? Icons.play_circle_filled_rounded
                    : Icons.article_rounded,
                color: isVideo ? Colors.redAccent : Colors.blueAccent,
              ),
            ),
            title: Text(res['title'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(type),
            trailing: const Icon(Icons.open_in_new_rounded, size: 18),
            onTap: () async {
              final query = Uri.encodeComponent(res['title'] ?? '');
              final url = isVideo
                  ? 'https://www.youtube.com/results?search_query=$query'
                  : 'https://www.google.com/search?q=$query';

              if (!await launchUrl(Uri.parse(url))) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch link')),
                  );
                }
              }
            },
          ),
        );
      },
    );
  }
}
