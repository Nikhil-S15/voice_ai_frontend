import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/splash/languagueselectionscreen.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class PharynxCancerPage extends StatefulWidget {
  final String userId;
  final String sessionId;

  const PharynxCancerPage({
    Key? key,
    required this.userId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<PharynxCancerPage> createState() => _PharynxCancerPageState();
}

class _PharynxCancerPageState extends State<PharynxCancerPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // Diagnosis
  String? diagnosis;
  List<String> diagnosisMethods = [];
  List<String> tumorSites = [];
  String? tumorLaterality;

  // Tumor characteristics
  String? histology, tumorGrade;
  final tStageController = TextEditingController();
  final nStageController = TextEditingController();
  final mStageController = TextEditingController();
  final clinicalStageController = TextEditingController();

  // Risk factors & comorbidity
  List<String> riskFactors = [];
  List<String> medicalHistory = [];
  List<String> symptoms = [];

  // Function scores
  final voiceScoreController = TextEditingController();
  final swallowingScoreController = TextEditingController();
  final breathingScoreController = TextEditingController();
  final nutritionScoreController = TextEditingController();
  final airwayScoreController = TextEditingController();
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
        diagnosis = data['diagnosis']?['confirmed'];
        diagnosisMethods = List<String>.from(
          data['diagnosis']?['methods'] ?? [],
        );
        tumorSites = List<String>.from(data['diagnosis']?['tumorSite'] ?? []);
        tumorLaterality = data['diagnosis']?['laterality'];

        histology = data['histogram']?['histology'];
        tumorGrade = data['histogram']?['grade'];
        tStageController.text = data['histogram']?['tStage'] ?? '';
        nStageController.text = data['histogram']?['nStage'] ?? '';
        mStageController.text = data['histogram']?['m'] ?? '';
        clinicalStageController.text =
            data['histogram']?['clinicalStage'] ?? '';

        riskFactors = List<String>.from(data['riskFactors'] ?? []);
        medicalHistory = List<String>.from(data['medicalHistory'] ?? []);
        symptoms = List<String>.from(data['symptoms'] ?? []);

        voiceScoreController.text = data['functionalVoice']?.toString() ?? '';
        swallowingScoreController.text =
            data['functionalSwallowing']?.toString() ?? '';
        breathingScoreController.text =
            data['functionalBreathing']?.toString() ?? '';
        nutritionScoreController.text =
            data['functionalNutrition']?.toString() ?? '';
        airwayScoreController.text = data['functionalAirway']?.toString() ?? '';

        treatmentModalities = List<String>.from(
          data['treatmentModalities'] ?? [],
        );
        surgeryType = data['treatmentDetails']?['surgeryType'];
        reconstructionType = data['treatmentDetails']?['reconstructionType'];
        marginStatus = data['treatmentDetails']?['marginStatus'];

        radiationDoseController.text = data['radiationDose']?.toString() ?? '';
        radiationTargets = List<String>.from(data['radiationTargets'] ?? []);
        radiationTechnique = data['radiationTechnique'];

        chemoAgentsController.text = data['chemoAgents'] ?? '';
        chemoScheduleController.text = data['chemoSchedule'] ?? '';
        chemoCompleted = data['chemoCompleted'];

        followupDateController.text = data['followupDate'] ?? '';
        followupStatus = data['followupStatus'];

        tracheostomy = data['outcomes']?['tracheostomy'];
        feedingStatus = data['outcomes']?['feedingStatus'];
        speechStatus = data['outcomes']?['speechStatus'];
      });
    }
  }

  // Treatment
  List<String> treatmentModalities = [];
  String? surgeryType, reconstructionType, marginStatus;
  final radiationDoseController = TextEditingController();
  List<String> radiationTargets = [];
  String? radiationTechnique;
  final chemoAgentsController = TextEditingController();
  final chemoScheduleController = TextEditingController();
  String? chemoCompleted;

  // Follow-up & outcomes
  final followupDateController = TextEditingController();
  String? followupStatus;
  String? tracheostomy, feedingStatus, speechStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pharynx Cancer', style: AppTextStyles.appBarTitle),
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
            SectionHeader(title: 'Diagnosis', icon: Icons.medical_services),
            AppRadioGroup(
              label: 'Confirmed diagnosis? *',
              options: const ['Yes', 'No', 'Not certain'],
              value: diagnosis,
              onChanged: (v) => setState(() => diagnosis = v),
            ),

            if (diagnosis == 'Yes') ...[
              AppCheckboxGroup(
                label: 'Diagnosis confirmed by:',
                options: const [
                  'Clinical examination',
                  'Biopsy/pathology',
                  'Imaging',
                ],
                selectedValues: diagnosisMethods,
                onChanged: (v) => setState(() => diagnosisMethods = v ?? []),
              ),
              AppCheckboxGroup(
                label: 'Tumor site:',
                options: const [
                  'Nasopharynx',
                  'Oropharynx',
                  'Hypopharynx',
                  'Other',
                ],
                selectedValues: tumorSites,
                onChanged: (v) => setState(() => tumorSites = v ?? []),
              ),
              AppRadioGroup(
                label: 'Tumor laterality:',
                options: const ['Right', 'Left', 'Bilateral', 'Midline'],
                value: tumorLaterality,
                onChanged: (v) => setState(() => tumorLaterality = v),
              ),
            ],

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Tumor Characteristics',
                icon: Icons.biotech,
                required: false,
              ),
              AppRadioGroup(
                label: 'Histological subtype:',
                options: const [
                  'Squamous cell carcinoma',
                  'Undifferentiated carcinoma',
                  'Lymphoepithelioma',
                  'Adenocarcinoma',
                  'Other',
                ],
                value: histology,
                onChanged: (v) => setState(() => histology = v),
              ),
              AppRadioGroup(
                label: 'Tumor grade:',
                options: const [
                  'Well-differentiated',
                  'Moderately differentiated',
                  'Poorly differentiated',
                  'Unknown',
                ],
                value: tumorGrade,
                onChanged: (v) => setState(() => tumorGrade = v),
              ),
              AppTextFormField(
                controller: tStageController,
                labelText: 'T Stage',
              ),
              AppTextFormField(
                controller: nStageController,
                labelText: 'N Stage',
              ),
              AppTextFormField(
                controller: mStageController,
                labelText: 'M Stage',
              ),
              AppTextFormField(
                controller: clinicalStageController,
                labelText: 'Clinical stage',
              ),
            ],

            SectionHeader(
              title: 'Risk Factors',
              icon: Icons.warning,
              required: false,
            ),
            AppCheckboxGroup(
              label: 'Risk factors:',
              options: const [
                'Tobacco - smoking',
                'Tobacco - chewing',
                'Alcohol',
                'HPV',
                'EBV',
                'Poor oral hygiene',
                'Other',
              ],
              selectedValues: riskFactors,
              onChanged: (v) => setState(() => riskFactors = v ?? []),
            ),
            AppCheckboxGroup(
              label: 'Medical history:',
              options: const [
                'Diabetes',
                'Hypertension',
                'Cardiovascular disease',
                'Chronic lung disease',
                'Immunosuppression',
                'Prior head & neck cancer',
                'Other',
              ],
              selectedValues: medicalHistory,
              onChanged: (v) => setState(() => medicalHistory = v ?? []),
            ),

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Symptoms',
                icon: Icons.health_and_safety,
                required: false,
              ),
              AppCheckboxGroup(
                label: 'Presenting symptoms:',
                options: const [
                  'Neck mass',
                  'Nasal obstruction',
                  'Hearing loss',
                  'Otalgia',
                  'Dysphagia',
                  'Odynophagia',
                  'Weight loss',
                  'Cranial nerve palsy',
                  'Other',
                ],
                selectedValues: symptoms,
                onChanged: (v) => setState(() => symptoms = v ?? []),
              ),
            ],

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Functional Assessment',
                icon: Icons.assessment,
                required: false,
              ),
              AppTextFormField(
                controller: voiceScoreController,
                labelText: 'Voice score (0-10)',
                keyboardType: TextInputType.number,
                validator: _validateScore,
              ),
              AppTextFormField(
                controller: swallowingScoreController,
                labelText: 'Swallowing score (0-10)',
                keyboardType: TextInputType.number,
                validator: _validateScore,
              ),
              AppTextFormField(
                controller: breathingScoreController,
                labelText: 'Breathing score (0-10)',
                keyboardType: TextInputType.number,
                validator: _validateScore,
              ),
              AppTextFormField(
                controller: nutritionScoreController,
                labelText: 'Nutrition score (0-10)',
                keyboardType: TextInputType.number,
                validator: _validateScore,
              ),
              AppTextFormField(
                controller: airwayScoreController,
                labelText: 'Airway score (0-10)',
                keyboardType: TextInputType.number,
                validator: _validateScore,
              ),
            ],

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Treatment',
                icon: Icons.medical_information,
                required: false,
              ),
              AppCheckboxGroup(
                label: 'Treatment modalities:',
                options: const [
                  'Surgery',
                  'Radiotherapy',
                  'Chemotherapy',
                  'Concurrent chemoradiation',
                  'Immunotherapy',
                  'Targeted therapy',
                  'Palliative care',
                  'No treatment',
                ],
                selectedValues: treatmentModalities,
                onChanged: (v) => setState(() => treatmentModalities = v ?? []),
              ),

              if (treatmentModalities.contains('Surgery')) ...[
                AppRadioGroup(
                  label: 'Surgery type:',
                  options: const [
                    'Transoral resection',
                    'Open resection',
                    'Neck dissection',
                    'Skull base surgery',
                    'Other',
                  ],
                  value: surgeryType,
                  onChanged: (v) => setState(() => surgeryType = v),
                ),
                AppRadioGroup(
                  label: 'Reconstruction:',
                  options: const ['None', 'Local flap', 'Free flap'],
                  value: reconstructionType,
                  onChanged: (v) => setState(() => reconstructionType = v),
                ),
                AppRadioGroup(
                  label: 'Margin status:',
                  options: const ['Clear', 'Close (<5mm)', 'Involved'],
                  value: marginStatus,
                  onChanged: (v) => setState(() => marginStatus = v),
                ),
              ],

              if (treatmentModalities.contains('Radiotherapy')) ...[
                AppTextFormField(
                  controller: radiationDoseController,
                  labelText: 'Radiation dose (Gy)',
                  keyboardType: TextInputType.number,
                ),
                AppCheckboxGroup(
                  label: 'Radiation target:',
                  options: const ['Primary site', 'Neck', 'Both'],
                  selectedValues: radiationTargets,
                  onChanged: (v) => setState(() => radiationTargets = v ?? []),
                ),
                AppRadioGroup(
                  label: 'Radiation technique:',
                  options: const ['IMRT', '3DCRT', 'Other'],
                  value: radiationTechnique,
                  onChanged: (v) => setState(() => radiationTechnique = v),
                ),
              ],

              if (treatmentModalities.contains('Chemotherapy')) ...[
                AppTextFormField(
                  controller: chemoAgentsController,
                  labelText: 'Chemo agents',
                ),
                AppTextFormField(
                  controller: chemoScheduleController,
                  labelText: 'Schedule',
                ),
                AppRadioGroup(
                  label: 'Chemo completed?',
                  options: const ['Yes', 'No', 'Discontinued'],
                  value: chemoCompleted,
                  onChanged: (v) => setState(() => chemoCompleted = v),
                ),
              ],
            ],

            SectionHeader(
              title: 'Follow-up',
              icon: Icons.calendar_today,
              required: false,
            ),
            AppTextFormField(
              controller: followupDateController,
              labelText: 'Follow-up date *',
              readOnly: true, // Prevents keyboard from opening
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000), // Earliest date selectable
                  lastDate: DateTime(2100), // Latest date selectable
                );
                if (pickedDate != null) {
                  String formattedDate = DateFormat(
                    'yyyy-MM-dd',
                  ).format(pickedDate);
                  setState(() {
                    followupDateController.text = formattedDate;
                  });
                }
              },
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            AppRadioGroup(
              label: 'Follow-up status: *',
              options: const [
                'No evidence of disease',
                'Persistent disease',
                'Recurrent disease',
                'Metastatic',
                'Deceased',
              ],
              value: followupStatus,
              onChanged: (v) => setState(() => followupStatus = v),
            ),

            if (diagnosis == 'Yes') ...[
              SectionHeader(title: 'Outcomes', icon: Icons.record_voice_over),
              AppRadioGroup(
                label: 'Tracheostomy:',
                options: const ['Yes', 'No', 'Temporary'],
                value: tracheostomy,
                onChanged: (v) => setState(() => tracheostomy = v),
              ),
              AppRadioGroup(
                label: 'Feeding status:',
                options: const ['Full oral', 'Modified oral', 'Tube feeding'],
                value: feedingStatus,
                onChanged: (v) => setState(() => feedingStatus = v),
              ),
              AppRadioGroup(
                label: 'Speech status:',
                options: const ['Normal', 'Impaired', 'Non-verbal', 'Uses aid'],
                value: speechStatus,
                onChanged: (v) => setState(() => speechStatus = v),
              ),
            ],

            const SizedBox(height: 32),
            AppElevatedButton(
              onPressed: isLoading ? null : _submitForm,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit All Forms'),
            ),
          ],
        ),
      ),
    );
  }

  String? _validateScore(String? value) {
    if (value?.isNotEmpty ?? false) {
      final score = int.tryParse(value!);
      if (score == null || score < 0 || score > 10) {
        return 'Enter score 0-10';
      }
    }
    return null;
  }

  bool _validateAllFields() {
    // Only require diagnosis confirmation and follow-up status
    if (diagnosis == null) return false;
    if (followupStatus == null) return false;
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
        'userId': widget.userId,
        'sessionId': widget.sessionId,
        'startedAt': now.toIso8601String(),
        'completedAt': now.toIso8601String(),
        'respondentIdentity': 'Patient',
        // Diagnosis
        'diagnosisConfirmed': diagnosis!,
        'diagnosisMethods': diagnosisMethods,
        'tumorSite': tumorSites,
        'tumorLaterality': tumorLaterality,
        // Tumor characteristics
        'histology': histology != null ? [histology!] : null,
        'tumorGrade': tumorGrade != null ? [tumorGrade!] : null,
        'tStage': tStageController.text.trim(),
        'nStage': nStageController.text.trim(),
        'mStage': mStageController.text.trim(),
        'clinicalStage': clinicalStageController.text.trim(),
        // Risk factors
        'riskFactors': riskFactors,
        'medicalHistory': medicalHistory,
        'symptoms': symptoms,
        // Functional assessment
        'functionalVoice': int.tryParse(voiceScoreController.text.trim()),
        'functionalSwallowing': int.tryParse(
          swallowingScoreController.text.trim(),
        ),
        'functionalBreathing': int.tryParse(
          breathingScoreController.text.trim(),
        ),
        'functionalNutrition': int.tryParse(
          nutritionScoreController.text.trim(),
        ),
        'functionalAirway': int.tryParse(airwayScoreController.text.trim()),
        // Treatment
        'treatmentModalities': treatmentModalities,
        'treatmentSurgeryDetails': surgeryType != null ? [surgeryType!] : null,
        'treatmentReconstruction': reconstructionType != null
            ? [reconstructionType!]
            : null,
        'treatmentMarginStatus': marginStatus != null ? [marginStatus!] : null,
        'radiationDose': radiationDoseController.text.trim(),
        'radiationTarget': radiationTargets,
        'radiationTechnique': radiationTechnique != null
            ? [radiationTechnique!]
            : null,
        'chemoAgents': chemoAgentsController.text.trim(),
        'chemoSchedule': chemoScheduleController.text.trim(),
        'chemoCompleted': chemoCompleted,
        // Follow-up
        'followupDate': followupDateController.text.trim(),
        'followupStatus': [followupStatus!],
        // Outcomes
        'outcomeTracheostomy': tracheostomy != null ? [tracheostomy!] : null,
        'outcomeFeeding': feedingStatus != null ? [feedingStatus!] : null,
        'outcomeSpeech': speechStatus != null ? [speechStatus!] : null,
        'date': DateFormat('yyyy-MM-dd').format(now),
      };
      // Remove null values from the payload
      final cleanPayload = payload
        ..removeWhere(
          (key, value) =>
              value == null ||
              value == '' ||
              (value is List && value.isEmpty) ||
              (value is Map && value.isEmpty),
        );
      debugPrint('Final payload: ${jsonEncode(cleanPayload)}');

      await ApiService.saveSessionProgress(
        userId: widget.userId,
        sessionId: widget.sessionId,
        currentPage: '/pharynx-cancer',
        progressData: payload, // or progressData if you’ve defined that map
      );

      // Submit final form
      final response = await ApiService.submitPharynxCancerData(payload);

      if (response['success'] == true) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => LanguageSelectionPage(
              userId: widget.userId,
              sessionId: widget.sessionId,
            ),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Submission failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    tStageController.dispose();
    nStageController.dispose();
    mStageController.dispose();
    clinicalStageController.dispose();
    voiceScoreController.dispose();
    swallowingScoreController.dispose();
    breathingScoreController.dispose();
    nutritionScoreController.dispose();
    airwayScoreController.dispose();
    radiationDoseController.dispose();
    chemoAgentsController.dispose();
    chemoScheduleController.dispose();
    followupDateController.dispose();
    super.dispose();
  }
}
