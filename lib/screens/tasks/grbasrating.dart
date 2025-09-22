import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/feedback/vhi_questionnaire_screen.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class GRBASRatingScreen extends StatefulWidget {
  final String userId;
  final String sessionId;
  final String language;

  const GRBASRatingScreen({
    Key? key,
    required this.userId,
    required this.sessionId,
    required this.language,
  }) : super(key: key);

  @override
  State<GRBASRatingScreen> createState() => _GRBASRatingScreenState();
}

class _GRBASRatingScreenState extends State<GRBASRatingScreen> {
  final _formKey = GlobalKey<FormState>();

  // Scores
  int? gScore;
  int? rScore;
  int? bScore;
  int? aScore;
  int? sScore;

  final TextEditingController _clinicianController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  DateTime evaluationDate = DateTime.now();
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    try {
      final saved = await ApiService.fetchSessionProgress(
        widget.userId,
        widget.sessionId,
      );
      if (saved != null && saved['progressData'] != null) {
        final data = saved['progressData'];
        setState(() {
          gScore = data['gScore'];
          rScore = data['rScore'];
          bScore = data['bScore'];
          aScore = data['aScore'];
          sScore = data['sScore'];

          _clinicianController.text = data['clinicianName'] ?? '';
          _commentsController.text = data['comments'] ?? '';

          if (data['evaluationDate'] != null) {
            try {
              evaluationDate = DateTime.parse(data['evaluationDate']);
            } catch (_) {}
          }
        });
      }
    } catch (e) {
      debugPrint('Error restoring GRBAS progress: $e');
    }
  }

  Widget _scoreSelector(
    String title,
    String description,
    ValueChanged<int?> onChanged,
    int? value,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: AppTextStyles.bodyText.copyWith(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (index) {
                return Column(
                  children: [
                    Text(
                      index.toString(),
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Radio<int>(
                      value: index,
                      groupValue: value,
                      onChanged: onChanged,
                      activeColor: AppColors.primary,
                    ),
                    Text(
                      _getScoreLabel(index),
                      style: AppTextStyles.bodyText.copyWith(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  String _getScoreLabel(int score) {
    switch (score) {
      case 0:
        return 'Normal';
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Severe';
      default:
        return '';
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate() ||
        gScore == null ||
        rScore == null ||
        bScore == null ||
        aScore == null ||
        sScore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all required fields")),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(evaluationDate);

      final progressData = {
        'gScore': gScore,
        'rScore': rScore,
        'bScore': bScore,
        'aScore': aScore,
        'sScore': sScore,
        'clinicianName': _clinicianController.text,
        'comments': _commentsController.text,
        'evaluationDate': dateStr,
      };

      // Save progress
      await ApiService.saveSessionProgress(
        userId: widget.userId,
        sessionId: widget.sessionId,
        currentPage: 'grbas-rating',
        progressData: progressData,
      );

      // Submit final data
      final response = await ApiService.submitGRBASRating(
        userId: widget.userId,
        sessionId: widget.sessionId,
        taskNumber: 1,
        gScore: gScore!,
        rScore: rScore!,
        bScore: bScore!,
        aScore: aScore!,
        sScore: sScore!,
        clinicianName: _clinicianController.text,
        evaluationDate: dateStr,
        comments: _commentsController.text,
      );

      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ GRBAS rating submitted successfully"),
          ),
        );

        // Navigate to VHIScreen after submission
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VHIAssessmentPage(
              userId: widget.userId,
              sessionId: widget.sessionId,
              language: widget.language,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? "Failed to submit")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "GRBAS Voice Rating",
          style: AppTextStyles.appBarTitle,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionHeader(
              title: "GRBAS Voice Assessment",
              icon: Icons.record_voice_over,
            ),

            Text(
              "This form is used by a trained clinician to assess a participant's voice using the GRBAS scale. "
              "Please rate each parameter from 0 (Normal) to 3 (Severe).",
              style: AppTextStyles.bodyText.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            _scoreSelector(
              "G – Grade",
              "Overall severity of voice abnormality",
              (val) => setState(() => gScore = val),
              gScore,
            ),

            _scoreSelector(
              "R – Roughness",
              "Perceived irregularity in the voice (e.g., hoarseness)",
              (val) => setState(() => rScore = val),
              rScore,
            ),

            _scoreSelector(
              "B – Breathiness",
              "Auditory impression of air leakage",
              (val) => setState(() => bScore = val),
              bScore,
            ),

            _scoreSelector(
              "A – Asthenia",
              "Weakness or lack of vocal power",
              (val) => setState(() => aScore = val),
              aScore,
            ),

            _scoreSelector(
              "S – Strain",
              "Perceived excessive effort during phonation",
              (val) => setState(() => sScore = val),
              sScore,
            ),

            SectionHeader(title: "Clinician Information", icon: Icons.person),

            AppTextFormField(
              controller: _clinicianController,
              labelText: "Clinician Name *",
              validator: (val) => val?.isEmpty ?? true ? "Required" : null,
            ),

            const SizedBox(height: 16),
            Text(
              "Date of Evaluation *",
              style: AppTextStyles.bodyText.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: AppColors.primary,
                ),
                title: Text(DateFormat('yyyy-MM-dd').format(evaluationDate)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppColors.primary),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: evaluationDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              onSurface: Colors.black,
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => evaluationDate = picked);
                    }
                  },
                ),
              ),
            ),

            SectionHeader(
              title: "Additional Comments",
              icon: Icons.comment,
              required: false,
            ),

            // Use standard TextFormField instead of AppTextFormField for multi-line support
            TextFormField(
              controller: _commentsController,
              decoration: InputDecoration(
                labelText: "Comments (optional)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: 3,
              style: AppTextStyles.bodyText,
            ),

            const SizedBox(height: 24),
            AppElevatedButton(
              onPressed: isSubmitting ? null : _submitForm,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit GRBAS Rating"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
