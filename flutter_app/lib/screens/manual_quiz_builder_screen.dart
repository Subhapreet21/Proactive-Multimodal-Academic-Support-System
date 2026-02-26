import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/quiz_model.dart';
import '../providers/quiz_provider.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';
import '../services/auth_service.dart';

// ─────────────────────────────────────────────
// A small data class for holding a single question's form state
// ─────────────────────────────────────────────
class _QuestionFormData {
  final TextEditingController questionText;
  final TextEditingController optionA;
  final TextEditingController optionB;
  final TextEditingController optionC;
  final TextEditingController optionD;
  final TextEditingController explanation;
  String? correctAnswer; // Key like 'A', 'B', 'C', 'D'

  _QuestionFormData({
    String? question,
    String? qA,
    String? qB,
    String? qC,
    String? qD,
    String? qExpl,
    this.correctAnswer,
  })  : questionText = TextEditingController(text: question),
        optionA = TextEditingController(text: qA),
        optionB = TextEditingController(text: qB),
        optionC = TextEditingController(text: qC),
        optionD = TextEditingController(text: qD),
        explanation = TextEditingController(text: qExpl);

  void dispose() {
    questionText.dispose();
    optionA.dispose();
    optionB.dispose();
    optionC.dispose();
    optionD.dispose();
    explanation.dispose();
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class ManualQuizBuilderScreen extends StatefulWidget {
  final Quiz? quiz;
  const ManualQuizBuilderScreen({super.key, this.quiz});

  @override
  State<ManualQuizBuilderScreen> createState() =>
      _ManualQuizBuilderScreenState();
}

class _ManualQuizBuilderScreenState extends State<ManualQuizBuilderScreen> {
  final _formKey = GlobalKey<FormState>();

  // ── Quiz-level settings controllers ──────────
  final _titleController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '15');
  final _maxAttemptsController = TextEditingController(text: '3');

  DateTime? _validFrom;
  DateTime? _validUntil;
  String _targetYear = 'All';
  String _targetDepartment = 'CSE';

  // ── Questions list ───────────────────────────
  final List<_QuestionFormData> _questions = [];

  bool _isSaving = false;

  static const _years = ['All', '1', '2', '3', '4'];
  static const _departments = [
    'All',
    'CSE',
    'ECE',
    'EEE',
    'MECH',
    'CIVIL',
    'IT',
    'AIDS'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      final q = widget.quiz!;
      // Strip "Quiz: " prefix if present
      String title = q.title;
      if (title.startsWith('Quiz: ')) {
        title = title.replaceFirst('Quiz: ', '');
      }
      _titleController.text = title;
      _timeLimitController.text = (q.timeLimitMins ?? 15).toString();
      _maxAttemptsController.text = (q.maxAttempts ?? 3).toString();
      _validFrom = q.validFrom;
      _validUntil = q.validUntil;
      _targetYear = q.targetYear ?? 'All';
      _targetDepartment = q.targetDepartment ?? 'CSE';

      for (var item in q.content) {
        final opts = item['options'] as List<dynamic>? ?? [];
        final correctText = item['correctAnswer'] as String? ?? '';

        String? correctKey;
        if (opts.isNotEmpty && opts[0] == correctText) correctKey = 'A';
        if (opts.length > 1 && opts[1] == correctText) correctKey = 'B';
        if (opts.length > 2 && opts[2] == correctText) correctKey = 'C';
        if (opts.length > 3 && opts[3] == correctText) correctKey = 'D';

        _questions.add(_QuestionFormData(
          question: item['text'] ?? '',
          qA: opts.isNotEmpty ? opts[0] : '',
          qB: opts.length > 1 ? opts[1] : '',
          qC: opts.length > 2 ? opts[2] : '',
          qD: opts.length > 3 ? opts[3] : '',
          qExpl: item['explanation'] ?? '',
          correctAnswer: correctKey,
        ));
      }
    } else {
      _addQuestion(); // start with one blank question
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeLimitController.dispose();
    _maxAttemptsController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() {
    setState(() => _questions.add(_QuestionFormData()));
  }

  void _removeQuestion(int index) {
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A quiz must have at least one question')),
      );
      return;
    }
    setState(() {
      _questions[index].dispose();
      _questions.removeAt(index);
    });
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_validFrom ?? now)
          : (_validUntil ?? now.add(const Duration(days: 30))),
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: DateTime(now.year + 5),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primaryColor,
            onPrimary: Colors.white,
            surface: Color(0xFF1E293B),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => isFrom ? _validFrom = picked : _validUntil = picked);
    }
  }

  String _formatDate(DateTime? d) => d == null
      ? 'Tap to select'
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _saveQuiz({required bool publish}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_validFrom == null || _validUntil == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select Valid From and Valid Until dates')));
      return;
    }

    // Build the content array
    final contentArray = _questions.map((q) {
      final options = [
        q.optionA.text.trim(),
        q.optionB.text.trim(),
        if (q.optionC.text.trim().isNotEmpty) q.optionC.text.trim(),
        if (q.optionD.text.trim().isNotEmpty) q.optionD.text.trim(),
      ];

      // Resolve the actual text for the correct answer based on choice
      String resolvedCorrect;
      switch (q.correctAnswer) {
        case 'A':
          resolvedCorrect = q.optionA.text.trim();
          break;
        case 'B':
          resolvedCorrect = q.optionB.text.trim();
          break;
        case 'C':
          resolvedCorrect = q.optionC.text.trim();
          break;
        case 'D':
          resolvedCorrect = q.optionD.text.trim();
          break;
        default:
          resolvedCorrect = q.optionA.text.trim();
      }

      return {
        'text': q.questionText.text.trim(),
        'options': options,
        'correctAnswer': resolvedCorrect,
        'explanation': q.explanation.text.trim(),
      };
    }).toList();

    final payload = {
      'title': 'Quiz: ${_titleController.text.trim()}',
      'description':
          widget.quiz?.description ?? 'Manually created quiz by faculty.',
      'time_limit_mins': int.tryParse(_timeLimitController.text) ?? 15,
      'max_attempts': int.tryParse(_maxAttemptsController.text) ?? 3,
      'valid_from': _validFrom!.toIso8601String(),
      'valid_until': _validUntil!.toIso8601String(),
      'target_year': _targetYear,
      'target_department': _targetDepartment,
      'is_active': publish,
      'content': contentArray,
    };

    setState(() => _isSaving = true);

    try {
      final token = await AuthService().getToken();
      final isUpdate = widget.quiz != null;
      final url = isUpdate
          ? '${ApiService().baseUrl}/api/quizzes/${widget.quiz!.id}'
          : '${ApiService().baseUrl}/api/quizzes/manual';

      final response = await (isUpdate
          ? http.put(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Bypass-Tunnel-Reminder': 'true',
                'ngrok-skip-browser-warning': 'true',
              },
              body: jsonEncode(payload),
            )
          : http.post(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
                'Bypass-Tunnel-Reminder': 'true',
                'ngrok-skip-browser-warning': 'true',
              },
              body: jsonEncode(payload),
            ));

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (mounted) {
          Provider.of<QuizProvider>(context, listen: false).loadQuizzes();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(isUpdate
                ? 'Quiz updated successfully!'
                : (publish
                    ? 'Quiz published successfully!'
                    : 'Quiz saved as draft (Inactive).')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ));
          context.pop();
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Unknown error');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── UI Helpers ───────────────────────────────

  InputDecoration _inputDecoration(String label,
      {String? hint, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  Widget _sectionHeader(String title, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                  color: accent, borderRadius: BorderRadius.circular(4))),
          const SizedBox(width: 10),
          Text(title,
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
              widget.quiz != null ? 'Edit Quiz Content' : 'Manual Quiz Builder',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // ── STEP 1: Quiz Settings ─────────────────────
              _glassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionHeader('Quiz Settings', Colors.orangeAccent),
                    // Quiz Title
                    TextFormField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDecoration('Quiz Title *',
                          hint: 'e.g. Introduction to Python'),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    // Time Limit + Max Attempts side by side
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _timeLimitController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: _inputDecoration('Time Limit (mins) *'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _maxAttemptsController,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            decoration: _inputDecoration('Max Attempts *'),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Valid From + Valid Until
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(isFrom: true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Valid From *',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_validFrom),
                                    style: TextStyle(
                                      color: _validFrom == null
                                          ? Colors.white38
                                          : Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(isFrom: false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.12)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Valid Until *',
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 12)),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatDate(_validUntil),
                                    style: TextStyle(
                                      color: _validUntil == null
                                          ? Colors.white38
                                          : Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Target Year + Dept side by side
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target Year',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _targetYear,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: _inputDecoration('').copyWith(
                                    labelText: null,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10)),
                                items: _years
                                    .map((y) => DropdownMenuItem(
                                        value: y,
                                        child: Text(y == 'All'
                                            ? 'All Years'
                                            : 'Year $y')))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _targetYear = v!),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Target Department',
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.55),
                                      fontSize: 12)),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                value: _targetDepartment,
                                dropdownColor: const Color(0xFF1E293B),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 14),
                                decoration: _inputDecoration('').copyWith(
                                    labelText: null,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10)),
                                items: _departments
                                    .map((d) => DropdownMenuItem(
                                        value: d, child: Text(d)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _targetDepartment = v!),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── STEP 2: Questions ────────────────────────
              ..._questions.asMap().entries.map((entry) {
                final i = entry.key;
                final q = entry.value;
                return _glassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _sectionHeader(
                              'Question ${i + 1}', Colors.lightBlueAccent),
                          const Spacer(),
                          IconButton(
                            tooltip: 'Remove question',
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _removeQuestion(i),
                          ),
                        ],
                      ),
                      // Question text
                      TextFormField(
                        controller: q.questionText,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: _inputDecoration('Question Text *',
                            hint:
                                'e.g. What is the time complexity of QuickSort?'),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'Question text is required'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      // Options A & B
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: q.optionA,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Option A *'),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: q.optionB,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Option B *'),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Required'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Options C & D (optional)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: q.optionC,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Option C',
                                  hint: 'Optional'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: q.optionD,
                              style: const TextStyle(color: Colors.white),
                              decoration: _inputDecoration('Option D',
                                  hint: 'Optional'),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Correct Answer dropdown
                      DropdownButtonFormField<String>(
                        decoration: _inputDecoration('Correct Answer *'),
                        value: q.correctAnswer,
                        dropdownColor: const Color(0xFF1E293B),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        validator: (v) => (v == null || v.isEmpty)
                            ? 'Please select the correct answer'
                            : null,
                        items: [
                          if (q.optionA.text.trim().isNotEmpty)
                            const DropdownMenuItem(
                                value: 'A', child: Text('Option A')),
                          if (q.optionB.text.trim().isNotEmpty)
                            const DropdownMenuItem(
                                value: 'B', child: Text('Option B')),
                          if (q.optionC.text.trim().isNotEmpty)
                            const DropdownMenuItem(
                                value: 'C', child: Text('Option C')),
                          if (q.optionD.text.trim().isNotEmpty)
                            const DropdownMenuItem(
                                value: 'D', child: Text('Option D')),
                        ],
                        onChanged: (v) => setState(() => q.correctAnswer = v),
                      ),
                      const SizedBox(height: 12),
                      // Explanation
                      TextFormField(
                        controller: q.explanation,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 2,
                        decoration: _inputDecoration('Explanation',
                            hint:
                                'Optional: explain why this answer is correct'),
                      ),
                    ],
                  ),
                );
              }),

              // ── Add Question button ──────────────────────
              GestureDetector(
                onTap: _addQuestion,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.lightBlueAccent.withOpacity(0.5),
                        width: 1.5),
                    color: Colors.lightBlueAccent.withOpacity(0.06),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          color: Colors.lightBlueAccent),
                      SizedBox(width: 8),
                      Text('Add Another Question',
                          style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Action Bar ─────────────────────────
        bottomNavigationBar: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            border:
                Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: Row(
            children: [
              // Save as Draft
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSaving ? null : () => _saveQuiz(publish: false),
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Draft'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    side: const BorderSide(color: Colors.orangeAccent),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Publish immediately
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed:
                        _isSaving ? null : () => _saveQuiz(publish: true),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.publish_rounded, size: 18),
                    label: Text(_isSaving ? 'Saving...' : 'Publish Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
