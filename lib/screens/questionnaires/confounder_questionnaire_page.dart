import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/questionnaires/oral_cancer_page.dart';
import 'package:voice_ai_app/screens/splash/questionnaire_selection_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class ConfounderQuestionnairePage extends StatefulWidget {
  final String userId;
  final String sessionId;
  const ConfounderQuestionnairePage({
    Key? key,
    required this.userId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<ConfounderQuestionnairePage> createState() =>
      _ConfounderQuestionnairePageState();
}

class _ConfounderQuestionnairePageState
    extends State<ConfounderQuestionnairePage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // State variables
  String? tobaccoUse, alcoholUse, substanceUse, voiceUse, difficultyToday;
  List<String> tobaccoForms = [];
  String? currentTobaccoStatus;
  final ageStartedController = TextEditingController();
  final ageQuitController = TextEditingController();
  final durationTobaccoController = TextEditingController();
  final drinksController = TextEditingController();
  String? alcoholFrequency, alcoholRehab;
  final substanceTypeController = TextEditingController();
  String? substanceRecovery;
  final caffeineController = TextEditingController();
  final waterController = TextEditingController();
  final voiceOccupationController = TextEditingController();
  final voiceHoursController = TextEditingController();
  final fatigueScoreController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final saved = await ApiService.fetchSessionProgress(
      widget.userId,
      widget.sessionId,
    );
    if (saved != null) {
      final data = saved['progressData'];
      setState(() {
        tobaccoUse = data['tobaccoUse'];
        tobaccoForms = List<String>.from(data['tobaccoForms'] ?? []);
        currentTobaccoStatus = data['currentTobaccoStatus'];
        ageStartedController.text = data['ageStarted'] ?? '';
        ageQuitController.text = data['ageQuit'] ?? '';
        durationTobaccoController.text = data['durationYears'] ?? '';
        alcoholUse = data['alcoholUse'];
        alcoholFrequency = data['alcoholFrequency'];
        drinksController.text = data['drinksPerOccasion'] ?? '';
        alcoholRehab = data['alcoholRehab'];
        substanceUse = data['substanceUse'];
        substanceTypeController.text = data['substanceType'] ?? '';
        substanceRecovery = data['substanceRecovery'];
        caffeineController.text = data['caffeinePerDay'] ?? '';
        waterController.text = data['waterIntake'] ?? '';
        voiceUse = data['voiceUse'];
        voiceOccupationController.text = data['voiceOccupation'] ?? '';
        voiceHoursController.text = data['voiceHoursPerDay'] ?? '';
        fatigueScoreController.text = data['fatigueScore'] ?? '';
        difficultyToday = data['difficultyToday'];
        // Add any more fields you need
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Confounder Questionnaire",
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
            SectionHeader(title: "Tobacco Use", icon: Icons.smoking_rooms),
            AppRadioGroup(
              label: "Have you ever used tobacco? *",
              options: const ["Yes", "No"],
              value: tobaccoUse,
              onChanged: (val) => setState(() => tobaccoUse = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            if (tobaccoUse == "Yes") ...[
              AppCheckboxGroup(
                label: "Form of tobacco used: *",
                options: const [
                  "Cigarettes",
                  "Bidis",
                  "Hookah",
                  "Chewing tobacco",
                  "Gutka/Pan Masala",
                  "Other",
                ],
                selectedValues: tobaccoForms,
                onChanged: (v) => setState(() => tobaccoForms = v ?? []),
                validator: (values) => (values?.isEmpty ?? true)
                    ? 'Please select at least one option'
                    : null,
              ),
              AppRadioGroup(
                label: "Current tobacco use status: *",
                options: const ["Daily", "Occasionally", "Not at all", "Quit"],
                value: currentTobaccoStatus,
                onChanged: (val) => setState(() => currentTobaccoStatus = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              AppTextFormField(
                controller: ageStartedController,
                labelText: "Age when you started *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
              if (currentTobaccoStatus == "Quit")
                AppTextFormField(
                  controller: ageQuitController,
                  labelText: "Age when you quit *",
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Required';
                    if (int.tryParse(value!) == null)
                      return 'Enter valid number';
                    return null;
                  },
                ),
              AppTextFormField(
                controller: durationTobaccoController,
                labelText: "Duration of use (years) *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
            ],

            SectionHeader(title: "Alcohol Use", icon: Icons.local_bar),
            AppRadioGroup(
              label: "Do you consume alcohol? *",
              options: const ["Yes", "No"],
              value: alcoholUse,
              onChanged: (val) => setState(() => alcoholUse = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            if (alcoholUse == "Yes") ...[
              AppRadioGroup(
                label: "Frequency of use: *",
                options: const ["Occasionally", "Weekly", "Daily", "Binge"],
                value: alcoholFrequency,
                onChanged: (val) => setState(() => alcoholFrequency = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
              AppTextFormField(
                controller: drinksController,
                labelText: "Typical number of drinks per occasion *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
              AppRadioGroup(
                label: "Ever received counseling for alcohol use? *",
                options: const ["Yes", "No"],
                value: alcoholRehab,
                onChanged: (val) => setState(() => alcoholRehab = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
            ],

            SectionHeader(title: "Substance Use", icon: Icons.medical_services),
            AppRadioGroup(
              label:
                  "Have you used recreational or non-prescribed substances? *",
              options: const ["Yes", "No"],
              value: substanceUse,
              onChanged: (val) => setState(() => substanceUse = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            if (substanceUse == "Yes") ...[
              AppTextFormField(
                controller: substanceTypeController,
                labelText: "If yes, specify type *",
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              AppRadioGroup(
                label: "Are you in recovery for substance use? *",
                options: const ["Yes", "No"],
                value: substanceRecovery,
                onChanged: (val) => setState(() => substanceRecovery = val),
                validator: (val) => val == null ? 'Required' : null,
              ),
            ],

            SectionHeader(
              title: "Caffeine & Hydration",
              icon: Icons.local_cafe,
              required: false,
            ),
            AppTextFormField(
              controller: caffeineController,
              labelText: "Average cups of caffeinated drinks/day",
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty ?? false) {
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                }
                return null;
              },
            ),
            AppTextFormField(
              controller: waterController,
              labelText: "Water intake (cups/day)",
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isNotEmpty ?? false) {
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                }
                return null;
              },
            ),

            SectionHeader(title: "Voice Usage", icon: Icons.record_voice_over),
            AppRadioGroup(
              label: "Use voice extensively? *",
              options: const ["Yes", "No"],
              value: voiceUse,
              onChanged: (val) => setState(() => voiceUse = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            if (voiceUse == "Yes") ...[
              AppTextFormField(
                controller: voiceOccupationController,
                labelText: "Occupation/activity *",
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              AppTextFormField(
                controller: voiceHoursController,
                labelText: "Hours/day of voice use *",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (int.tryParse(value!) == null) return 'Enter valid number';
                  return null;
                },
              ),
            ],

            SectionHeader(
              title: "Fatigue",
              icon: Icons.bedtime,
              required: false,
            ),
            AppTextFormField(
              controller: fatigueScoreController,
              labelText: "Fatigue score (0-10)",
              keyboardType: TextInputType.number,

              validator: (value) {
                if (value?.isNotEmpty ?? false) {
                  final score = int.tryParse(value!);
                  if (score == null) return 'Enter valid number';
                  if (score < 0 || score > 10) return 'Must be between 0-10';
                }
                return null;
              },
            ),
            AppRadioGroup(
              label: "Any difficulty today? ",
              options: const ["Yes", "No"],
              value: difficultyToday,
              onChanged: (val) => setState(() => difficultyToday = val),
              validator: (val) => val == null ? 'Required' : null,
            ),

            const SizedBox(height: 24),
            const Divider(),
            CheckboxListTile(
              title: Text(
                "I consent to participate in this questionnaire.",
                style: AppTextStyles.bodyText,
              ),
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),

            const SizedBox(height: 24),
            AppElevatedButton(
              onPressed: isLoading ? null : _submitForm,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Continue"),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  bool _validateAllFields() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }
    if (tobaccoUse == null ||
        alcoholUse == null ||
        substanceUse == null ||
        voiceUse == null ||
        difficultyToday == null) {
      return false;
    }
    if (tobaccoUse == "Yes") {
      if (tobaccoForms.isEmpty ||
          currentTobaccoStatus == null ||
          ageStartedController.text.isEmpty ||
          durationTobaccoController.text.isEmpty) {
        return false;
      }
      if (currentTobaccoStatus == "Quit" && ageQuitController.text.isEmpty) {
        return false;
      }
    }
    if (alcoholUse == "Yes") {
      if (alcoholFrequency == null ||
          drinksController.text.isEmpty ||
          alcoholRehab == null) {
        return false;
      }
    }
    if (substanceUse == "Yes") {
      if (substanceTypeController.text.isEmpty || substanceRecovery == null) {
        return false;
      }
    }
    if (voiceUse == "Yes") {
      if (voiceOccupationController.text.isEmpty ||
          voiceHoursController.text.isEmpty) {
        return false;
      }
    }
    return true;
  }

  Future<void> _submitForm() async {
    if (!_validateAllFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final payload = {
        "userId": widget.userId,
        "sessionId": widget.sessionId,
        "startedAt": now.toIso8601String(),
        "completedAt": now.toIso8601String(),
        "tobaccoUse": tobaccoUse,
        "tobaccoForms": tobaccoForms,
        "currentTobaccoStatus": currentTobaccoStatus,
        "ageStarted": ageStartedController.text.trim(),
        "ageQuit": ageQuitController.text.trim(),
        "durationYears": durationTobaccoController.text.trim(),
        "alcoholUse": alcoholUse,
        "alcoholFrequency": alcoholFrequency,
        "drinksPerOccasion": drinksController.text.trim(),
        "alcoholRehab": alcoholRehab,
        "substanceUse": substanceUse,
        "substanceType": substanceTypeController.text.trim(),
        "substanceRecovery": substanceRecovery,
        "caffeinePerDay": caffeineController.text.trim(),
        "waterIntake": waterController.text.trim(),
        "voiceUse": voiceUse,
        "voiceOccupation": voiceOccupationController.text.trim(),
        "voiceHoursPerDay": voiceHoursController.text.trim(),
        "fatigueScore": fatigueScoreController.text.trim(),
        "difficultyToday": difficultyToday,
        "date": DateFormat('yyyy-MM-dd').format(now),
      };

      debugPrint('Submitting confounder data: ${jsonEncode(payload)}');

      final progressData = {
        'tobaccoUse': tobaccoUse,
        'tobaccoForms': tobaccoForms,
        'currentTobaccoStatus': currentTobaccoStatus,
        'ageStarted': ageStartedController.text.trim(),
        'ageQuit': ageQuitController.text.trim(),
        'durationYears': durationTobaccoController.text.trim(),
        'alcoholUse': alcoholUse,
        'alcoholFrequency': alcoholFrequency,
        'drinksPerOccasion': drinksController.text.trim(),
        'alcoholRehab': alcoholRehab,
        'substanceUse': substanceUse,
        'substanceType': substanceTypeController.text.trim(),
        'substanceRecovery': substanceRecovery,
        'caffeinePerDay': caffeineController.text.trim(),
        'waterIntake': waterController.text.trim(),
        'voiceUse': voiceUse,
        'voiceOccupation': voiceOccupationController.text.trim(),
        'voiceHoursPerDay': voiceHoursController.text.trim(),
        'fatigueScore': fatigueScoreController.text.trim(),
        'difficultyToday': difficultyToday,
        // Add more as needed!
      };

      await ApiService.saveSessionProgress(
        userId: widget.userId,
        sessionId: widget.sessionId,
        currentPage: '/questionnaire-selection', // Update this
        progressData: progressData,
      );

      final response = await ApiService.submitConfounder(payload);

      if (response['success'] == true) {
        // Navigate to selection screen instead of directly to Oral Cancer
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuestionnaireSelectionPage(
              userId: widget.userId,
              sessionId: widget.sessionId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? "Submission failed"),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
}
