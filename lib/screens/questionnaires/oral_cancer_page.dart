import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';

import 'package:voice_ai_app/screens/questionnaires/pharynx_cancer_page.dart';
// import 'package:voice_ai_app/screens/questionnaires/larynx_hypopharynx_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class OralCancerPage extends StatefulWidget {
  final String userId;
  final String sessionId;

  const OralCancerPage({
    Key? key,
    required this.userId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<OralCancerPage> createState() => _OralCancerPageState();
}

class _OralCancerPageState extends State<OralCancerPage> {
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
  final painController = TextEditingController();
  final speechController = TextEditingController();
  final swallowingController = TextEditingController();
  final trismusController = TextEditingController();
  final nutritionController = TextEditingController();

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
        tumorSites = List<String>.from(data['diagnosis']?['tumorSites'] ?? []);
        tumorLaterality = data['diagnosis']?['laterality'];

        histology = data['tumorCharacteristics']?['histology'];
        tumorGrade = data['tumorCharacteristics']?['grade'];
        tStageController.text = data['tumorCharacteristics']?['tStage'] ?? '';
        nStageController.text = data['tumorCharacteristics']?['nStage'] ?? '';
        mStageController.text = data['tumorCharacteristics']?['mStage'] ?? '';
        clinicalStageController.text =
            data['tumorCharacteristics']?['clinicalStage'] ?? '';

        riskFactors = List<String>.from(data['riskFactors'] ?? []);
        medicalHistory = List<String>.from(data['medicalHistory'] ?? []);
        symptoms = List<String>.from(data['symptoms'] ?? []);

        painController.text = data['functionalScores']?['pain'] ?? '';
        speechController.text = data['functionalScores']?['speech'] ?? '';
        swallowingController.text =
            data['functionalScores']?['swallowing'] ?? '';
        trismusController.text = data['functionalScores']?['trismus'] ?? '';
        nutritionController.text = data['functionalScores']?['nutrition'] ?? '';

        treatmentModalities = List<String>.from(
          data['treatment']?['modalities'] ?? [],
        );
        surgeryType = data['treatment']?['surgery']?['type'];
        reconstructionType = data['treatment']?['surgery']?['reconstruction'];
        marginStatus = data['treatment']?['surgery']?['marginStatus'];

        radiationDoseController.text =
            data['treatment']?['radiotherapy']?['dose'] ?? '';
        radiationTargets = List<String>.from(
          data['treatment']?['radiotherapy']?['targets'] ?? [],
        );
        radiationTechnique = data['treatment']?['radiotherapy']?['technique'];

        chemoAgentsController.text =
            data['treatment']?['chemotherapy']?['agents'] ?? '';
        chemoScheduleController.text =
            data['treatment']?['chemotherapy']?['schedule'] ?? '';
        chemoCompleted = data['treatment']?['chemotherapy']?['completed'];

        followupDateController.text = data['followUp']?['date'] ?? '';
        followupStatus = data['followUp']?['status'];

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
        title: const Text('Oral Cancer Data', style: AppTextStyles.appBarTitle),
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
              label: 'Confirmed diagnosis of oral cancer? *',
              options: const ['Yes', 'No', 'Not certain'],
              value: diagnosis,
              onChanged: (v) => setState(() => diagnosis = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            if (diagnosis == 'Yes') ...[
              AppCheckboxGroup(
                label: 'Diagnosis confirmed by: *',
                options: const [
                  'Clinical examination',
                  'Biopsy/pathology',
                  'Imaging',
                ],
                selectedValues: diagnosisMethods,
                onChanged: (v) => setState(() => diagnosisMethods = v ?? []),
                validator: (values) => (values?.isEmpty ?? true)
                    ? 'Please select at least one method'
                    : null,
              ),
              AppCheckboxGroup(
                label: 'Tumor site: *',
                options: const [
                  'Buccal mucosa',
                  'Tongue',
                  'Floor of mouth',
                  'Alveolus',
                  'Retromolar trigone',
                  'Hard palate',
                  'Lip',
                  'Other',
                ],
                selectedValues: tumorSites,
                onChanged: (v) => setState(() => tumorSites = v ?? []),
                validator: (values) => (values?.isEmpty ?? true)
                    ? 'Please select at least one site'
                    : null,
              ),
              AppRadioGroup(
                label: 'Tumor laterality: *',
                options: const ['Right', 'Left', 'Bilateral', 'Midline'],
                value: tumorLaterality,
                onChanged: (v) => setState(() => tumorLaterality = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Tumor Characteristics',
                icon: Icons.biotech,
                required: false,
              ),
              AppRadioGroup(
                label: 'Histological subtype: *',
                options: const [
                  'Squamous cell carcinoma',
                  'Verrucous carcinoma',
                  'Basaloid SCC',
                  'Carcinoma in situ',
                  'Other',
                ],
                value: histology,
                onChanged: (v) => setState(() => histology = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              AppRadioGroup(
                label: 'Tumor grade: *',
                options: const [
                  'Well-differentiated',
                  'Moderately differentiated',
                  'Poorly differentiated',
                  'Unknown',
                ],
                value: tumorGrade,
                onChanged: (v) => setState(() => tumorGrade = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              AppTextFormField(
                controller: tStageController,
                labelText: 'T Stage *',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              AppTextFormField(
                controller: nStageController,
                labelText: 'N Stage *',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              AppTextFormField(
                controller: mStageController,
                labelText: 'M Stage *',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              AppTextFormField(
                controller: clinicalStageController,
                labelText: 'Clinical stage *',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
            ],

            SectionHeader(
              title: 'Risk Factors & Comorbidities',
              icon: Icons.warning,
              required: false,
            ),
            AppCheckboxGroup(
              label: 'Risk factors:',
              options: const [
                'Tobacco - smoking',
                'Tobacco - chewing',
                'Alcohol',
                'Betel nut',
                'Poor hygiene',
                'HPV',
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
                'Cardiovascular',
                'Lung disease',
                'Immunosuppression',
                'Prior cancer',
                'Other',
              ],
              selectedValues: medicalHistory,
              onChanged: (v) => setState(() => medicalHistory = v ?? []),
            ),

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Symptoms & Functional Impact',
                icon: Icons.health_and_safety,
                required: false,
              ),
              AppCheckboxGroup(
                label: 'Presenting symptoms: *',
                options: const [
                  'Ulcer',
                  'Pain',
                  'Trismus',
                  'Dysphagia',
                  'Odynophagia',
                  'Altered speech',
                  'Oral bleeding',
                  'Neck swelling',
                  'Weight loss',
                ],
                selectedValues: symptoms,
                onChanged: (v) => setState(() => symptoms = v ?? []),
                validator: (values) => (values?.isEmpty ?? true)
                    ? 'Please select at least one symptom'
                    : null,
              ),
              AppTextFormField(
                controller: painController,
                labelText: 'Pain score (0-10)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final score = int.tryParse(value!);
                    if (score == null) return 'Enter valid number';
                    if (score < 0 || score > 10) return 'Must be 0-10';
                  }
                  return null;
                },
              ),
              AppTextFormField(
                controller: speechController,
                labelText: 'Speech impairment (0-10)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final score = int.tryParse(value!);
                    if (score == null) return 'Enter valid number';
                    if (score < 0 || score > 10) return 'Must be 0-10';
                  }
                  return null;
                },
              ),
              AppTextFormField(
                controller: swallowingController,
                labelText: 'Swallowing difficulty (0-10)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final score = int.tryParse(value!);
                    if (score == null) return 'Enter valid number';
                    if (score < 0 || score > 10) return 'Must be 0-10';
                  }
                  return null;
                },
              ),
              AppTextFormField(
                controller: trismusController,
                labelText: 'Trismus score (0-10)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final score = int.tryParse(value!);
                    if (score == null) return 'Enter valid number';
                    if (score < 0 || score > 10) return 'Must be 0-10';
                  }
                  return null;
                },
              ),
              AppTextFormField(
                controller: nutritionController,
                labelText: 'Nutrition compromise (0-10)',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final score = int.tryParse(value!);
                    if (score == null) return 'Enter valid number';
                    if (score < 0 || score > 10) return 'Must be 0-10';
                  }
                  return null;
                },
              ),
            ],

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Treatment & Follow-up',
                icon: Icons.medical_information,
              ),
              AppCheckboxGroup(
                label: 'Treatment modalities: *',
                options: const [
                  'Surgery',
                  'Radiotherapy',
                  'Chemotherapy',
                  'Concurrent chemoradiation',
                  'Immunotherapy',
                  'Palliative care',
                  'No treatment',
                ],
                selectedValues: treatmentModalities,
                onChanged: (v) => setState(() => treatmentModalities = v ?? []),
                validator: (values) => (values?.isEmpty ?? true)
                    ? 'Please select at least one modality'
                    : null,
              ),

              if (treatmentModalities.contains('Surgery')) ...[
                AppRadioGroup(
                  label: 'Surgery type: *',
                  options: const [
                    'Wide excision',
                    'Mandibulectomy',
                    'Maxillectomy',
                    'Neck dissection',
                  ],
                  value: surgeryType,
                  onChanged: (v) => setState(() => surgeryType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                AppRadioGroup(
                  label: 'Reconstruction type: *',
                  options: const ['None', 'Local flap', 'Free flap'],
                  value: reconstructionType,
                  onChanged: (v) => setState(() => reconstructionType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                AppRadioGroup(
                  label: 'Margin status: *',
                  options: const ['Clear', 'Close (<5mm)', 'Involved'],
                  value: marginStatus,
                  onChanged: (v) => setState(() => marginStatus = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],

              if (treatmentModalities.contains('Radiotherapy')) ...[
                AppTextFormField(
                  controller: radiationDoseController,
                  labelText: 'Radiation dose (Gy) *',
                  keyboardType: TextInputType.number,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                AppCheckboxGroup(
                  label: 'Radiation target: *',
                  options: const ['Primary site', 'Neck', 'Both'],
                  selectedValues: radiationTargets,
                  onChanged: (v) => setState(() => radiationTargets = v ?? []),
                  validator: (values) =>
                      (values?.isEmpty ?? true) ? 'Required' : null,
                ),
                AppRadioGroup(
                  label: 'Radiation technique: *',
                  options: const ['IMRT', '3DCRT', 'Other'],
                  value: radiationTechnique,
                  onChanged: (v) => setState(() => radiationTechnique = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],

              if (treatmentModalities.contains('Chemotherapy')) ...[
                AppTextFormField(
                  controller: chemoAgentsController,
                  labelText: 'Chemo agents *',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                AppTextFormField(
                  controller: chemoScheduleController,
                  labelText: 'Schedule *',
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                AppRadioGroup(
                  label: 'Chemo completed? *',
                  options: const ['Yes', 'No', 'Discontinued'],
                  value: chemoCompleted,
                  onChanged: (v) => setState(() => chemoCompleted = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
              ],
            ],

            SectionHeader(
              title: 'Follow-up Information',
              icon: Icons.calendar_today,
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
                'No disease',
                'Persistent',
                'Recurrent',
                'Metastatic',
                'Deceased',
              ],
              value: followupStatus,
              onChanged: (v) => setState(() => followupStatus = v),
              validator: (v) => v == null ? 'Required' : null,
            ),

            if (diagnosis == 'Yes') ...[
              SectionHeader(
                title: 'Voice/Speech/Nutrition Outcomes',
                icon: Icons.record_voice_over,
                required: false,
              ),
              AppRadioGroup(
                label: 'Tracheostomy: *',
                options: const ['Yes', 'No', 'Temporary'],
                value: tracheostomy,
                onChanged: (v) => setState(() => tracheostomy = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              AppRadioGroup(
                label: 'Feeding status: *',
                options: const [
                  'Full oral',
                  'Modified oral',
                  'Nasogastric',
                  'Gastrostomy',
                ],
                value: feedingStatus,
                onChanged: (v) => setState(() => feedingStatus = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              AppRadioGroup(
                label: 'Speech status: *',
                options: const [
                  'Normal',
                  'Intelligible with effort',
                  'Non-verbal',
                  'Uses aid',
                ],
                value: speechStatus,
                onChanged: (v) => setState(() => speechStatus = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
            ],

            const SizedBox(height: 24),
            AppElevatedButton(
              onPressed: isLoading ? null : _submitForm,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Continue to Pharynx Cancer Form'),
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

    if (diagnosis == null) {
      return false;
    }

    if (followupDateController.text.isEmpty || followupStatus == null) {
      return false;
    }

    // Only validate cancer-specific fields if diagnosis is "Yes"
    if (diagnosis == 'Yes') {
      if (diagnosisMethods.isEmpty ||
          tumorSites.isEmpty ||
          tumorLaterality == null ||
          histology == null ||
          tumorGrade == null ||
          tStageController.text.isEmpty ||
          nStageController.text.isEmpty ||
          mStageController.text.isEmpty ||
          clinicalStageController.text.isEmpty ||
          symptoms.isEmpty ||
          treatmentModalities.isEmpty ||
          tracheostomy == null ||
          feedingStatus == null ||
          speechStatus == null) {
        return false;
      }

      // Validate treatment-specific fields
      if (treatmentModalities.contains('Surgery') &&
          (surgeryType == null ||
              reconstructionType == null ||
              marginStatus == null)) {
        return false;
      }

      if (treatmentModalities.contains('Radiotherapy') &&
          (radiationDoseController.text.isEmpty ||
              radiationTargets.isEmpty ||
              radiationTechnique == null)) {
        return false;
      }

      if (treatmentModalities.contains('Chemotherapy') &&
          (chemoAgentsController.text.isEmpty ||
              chemoScheduleController.text.isEmpty ||
              chemoCompleted == null)) {
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
        'userId': widget.userId,
        'sessionId': widget.sessionId,
        'startedAt': now.toIso8601String(),
        'completedAt': now.toIso8601String(),
        'diagnosis': {
          'confirmed': diagnosis,
          'methods': diagnosisMethods,
          'tumorSites': tumorSites,
          'laterality': tumorLaterality,
        },
        'tumorCharacteristics': diagnosis == 'Yes'
            ? {
                'histology': histology,
                'grade': tumorGrade,
                'tStage': tStageController.text.trim(),
                'nStage': nStageController.text.trim(),
                'mStage': mStageController.text.trim(),
                'clinicalStage': clinicalStageController.text.trim(),
              }
            : null,
        'riskFactors': riskFactors,
        'medicalHistory': medicalHistory,
        'symptoms': diagnosis == 'Yes' ? symptoms : null,
        'functionalScores': diagnosis == 'Yes'
            ? {
                'pain': painController.text.trim(),
                'speech': speechController.text.trim(),
                'swallowing': swallowingController.text.trim(),
                'trismus': trismusController.text.trim(),
                'nutrition': nutritionController.text.trim(),
              }
            : null,
        'treatment': diagnosis == 'Yes'
            ? {
                'modalities': treatmentModalities,
                'surgery': treatmentModalities.contains('Surgery')
                    ? {
                        'type': surgeryType,
                        'reconstruction': reconstructionType,
                        'marginStatus': marginStatus,
                      }
                    : null,
                'radiotherapy': treatmentModalities.contains('Radiotherapy')
                    ? {
                        'dose': radiationDoseController.text.trim(),
                        'targets': radiationTargets,
                        'technique': radiationTechnique,
                      }
                    : null,
                'chemotherapy': treatmentModalities.contains('Chemotherapy')
                    ? {
                        'agents': chemoAgentsController.text.trim(),
                        'schedule': chemoScheduleController.text.trim(),
                        'completed': chemoCompleted,
                      }
                    : null,
              }
            : null,
        'followUp': {
          'date': followupDateController.text.trim(),
          'status': followupStatus,
        },
        'outcomes': diagnosis == 'Yes'
            ? {
                'tracheostomy': tracheostomy,
                'feedingStatus': feedingStatus,
                'speechStatus': speechStatus,
              }
            : null,
        'date': DateFormat('yyyy-MM-dd').format(now),
      };

      debugPrint('Submitting oral cancer payload: ${jsonEncode(payload)}');

      final progressData = {
        'diagnosis': {
          'confirmed': diagnosis,
          'methods': diagnosisMethods,
          'tumorSites': tumorSites,
          'laterality': tumorLaterality,
        },
        'tumorCharacteristics': diagnosis == 'Yes'
            ? {
                'histology': histology,
                'grade': tumorGrade,
                'tStage': tStageController.text.trim(),
                'nStage': nStageController.text.trim(),
                'mStage': mStageController.text.trim(),
                'clinicalStage': clinicalStageController.text.trim(),
              }
            : null,
        'riskFactors': riskFactors,
        'medicalHistory': medicalHistory,
        'symptoms': diagnosis == 'Yes' ? symptoms : null,
        'functionalScores': diagnosis == 'Yes'
            ? {
                'pain': painController.text.trim(),
                'speech': speechController.text.trim(),
                'swallowing': swallowingController.text.trim(),
                'trismus': trismusController.text.trim(),
                'nutrition': nutritionController.text.trim(),
              }
            : null,
        'treatment': diagnosis == 'Yes'
            ? {
                'modalities': treatmentModalities,
                'surgery': treatmentModalities.contains('Surgery')
                    ? {
                        'type': surgeryType,
                        'reconstruction': reconstructionType,
                        'marginStatus': marginStatus,
                      }
                    : null,
                'radiotherapy': treatmentModalities.contains('Radiotherapy')
                    ? {
                        'dose': radiationDoseController.text.trim(),
                        'targets': radiationTargets,
                        'technique': radiationTechnique,
                      }
                    : null,
                'chemotherapy': treatmentModalities.contains('Chemotherapy')
                    ? {
                        'agents': chemoAgentsController.text.trim(),
                        'schedule': chemoScheduleController.text.trim(),
                        'completed': chemoCompleted,
                      }
                    : null,
              }
            : null,
        'followUp': {
          'date': followupDateController.text.trim(),
          'status': followupStatus,
        },
        'outcomes': diagnosis == 'Yes'
            ? {
                'tracheostomy': tracheostomy,
                'feedingStatus': feedingStatus,
                'speechStatus': speechStatus,
              }
            : null,
        'date': DateFormat('yyyy-MM-dd').format(now),
      };

      await ApiService.saveSessionProgress(
        userId: widget.userId,
        sessionId: widget.sessionId,
        currentPage:
            '/pharynx-cancer', // The next page route, update accordingly
        progressData: progressData,
      );

      final response = await ApiService.submitOralCancerData(payload);
      if (response?['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharynxCancerPage(
              userId: widget.userId,
              sessionId: widget.sessionId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response?['message'] ?? 'Submission failed')),
        );
      }
    } catch (e) {
      debugPrint('Error submitting oral cancer data: $e');
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
    painController.dispose();
    speechController.dispose();
    swallowingController.dispose();
    trismusController.dispose();
    nutritionController.dispose();
    radiationDoseController.dispose();
    chemoAgentsController.dispose();
    chemoScheduleController.dispose();
    followupDateController.dispose();
    super.dispose();
  }
}
