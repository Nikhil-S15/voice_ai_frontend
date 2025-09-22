import 'dart:convert';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/questionnaires/confounder_questionnaire_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
// import 'package:voice_ai_app/utils/progress_storage.dart' hide loadProgress;
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class DemographicsPage extends StatefulWidget {
  final int userId;
  final String sessionId;

  const DemographicsPage({
    Key? key,
    required this.userId,
    required this.sessionId,
  }) : super(key: key);

  @override
  State<DemographicsPage> createState() => _DemographicsPageState();
}

class _DemographicsPageState extends State<DemographicsPage> {
  final _formKey = GlobalKey<FormState>();
  final cityController = TextEditingController();
  final districtController = TextEditingController();
  final List<String> indianStates = [
    "Andhra Pradesh",
    "Arunachal Pradesh",
    "Assam",
    "Bihar",
    "Chhattisgarh",
    "Goa",
    "Gujarat",
    "Haryana",
    "Himachal Pradesh",
    "Jharkhand",
    "Karnataka",
    "Kerala",
    "Madhya Pradesh",
    "Maharashtra",
    "Manipur",
    "Meghalaya",
    "Mizoram",
    "Nagaland",
    "Odisha",
    "Punjab",
    "Rajasthan",
    "Sikkim",
    "Tamil Nadu",
    "Telangana",
    "Tripura",
    "Uttar Pradesh",
    "Uttarakhand",
    "West Bengal",
    "Andaman & Nicobar Islands",
    "Chandigarh",
    "Dadra & Nagar Haveli and Daman & Diu",
    "Delhi",
    "Jammu & Kashmir",
    "Ladakh",
    "Lakshadweep",
    "Puducherry",
  ];
  String? selectedState;

  final pincodeController = TextEditingController();
  final ageController = TextEditingController();
  final occupationController = TextEditingController();
  final householdSizeController = TextEditingController();

  String? respondentIdentity,
      country,
      gender,
      education,
      employment,
      income,
      residence,
      maritalStatus,
      transport;
  List<String> coResidents = [];
  List<String> disability = [];
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    final saved = await ApiService.fetchSessionProgress(
      widget.userId.toString(),
      widget.sessionId,
    );
    if (saved != null) {
      final data = saved['progressData'];
      setState(() {
        cityController.text = data['city'] ?? '';
        districtController.text = data['district'] ?? '';
        selectedState = data['state'];
        pincodeController.text = data['pincode'] ?? '';
        respondentIdentity = data['respondentIdentity'];
        country = data['country'];
        gender = data['gender'];
        ageController.text = data['age'] ?? '';
        education = data['education'];
        employment = data['employment'];
        occupationController.text = data['occupation'] ?? '';
        income = data['income'];
        residence = data['residence'];
        maritalStatus = data['maritalStatus'];
        householdSizeController.text = data['householdSize'] ?? '';
        coResidents = List<String>.from(data['coResidents'] ?? []);
        transport = data['transport'];
        disability = List<String>.from(data['disability'] ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Demographics', style: AppTextStyles.appBarTitle),
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
              title: "Respondent Identity ",
              icon: Icons.perm_identity,
              required: true,
            ),

            AppRadioGroup(
              label: "Who is completing this form?",
              options: const ["Self", "Assistant", "Parent/Caregiver"],
              value: respondentIdentity,
              onChanged: (val) => setState(() => respondentIdentity = val),
              validator: (val) => val == null ? 'Required' : null,
            ),

            SectionHeader(
              title: "Address Information",
              icon: Icons.location_on,
              required: true,
            ),
            AppTextFormField(
              controller: cityController,
              labelText: 'City/Town/Village',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: districtController,
              labelText: 'District',
              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppDropdown(
              label: "State/UT",
              value: selectedState,
              items: indianStates,
              onChanged: (val) => setState(() => selectedState = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: pincodeController,
              labelText: 'Pincode',
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // only digits
              ],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                if (value.length != 6) return 'Pincode must be 6 digits';
                return null;
              },
            ),

            const SizedBox(height: 12),
            AppRadioGroup(
              label: "Country",
              options: const ["India", "Other"],
              value: country,
              onChanged: (val) => setState(() => country = val ?? "India"),
              validator: (val) => val == null ? 'Required' : null,
            ),

            SectionHeader(
              title: "Personal Information",
              icon: Icons.person_outline,
              required: true,
            ),
            AppRadioGroup(
              label: "Gender Identity",
              options: const [
                "Male",
                "Female",
                "Non-binary/Other",
                "Prefer not to say",
              ],
              value: gender,
              onChanged: (val) => setState(() => gender = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: ageController,
              labelText: 'Age (in years)',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null || value.isEmpty) return 'Required';
                final age = int.tryParse(value);
                if (age == null) return 'Enter a valid number';
                if (age < 1 || age > 120) return 'Enter a realistic age';
                return null;
              },
            ),

            const SizedBox(height: 12),
            AppDropdown(
              label: "Educational Qualification",
              value: education,
              items: const [
                "No formal education",
                "Primary (up to 5th std)",
                "Secondary (6th–10th std)",
                "Higher Secondary (11th–12th std)",
                "Graduate",
                "Postgraduate or higher",
                "Prefer not to say",
              ],
              onChanged: (val) => setState(() => education = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppDropdown(
              label: "Employment Status",
              value: employment,
              items: const [
                "Employed – Full-time",
                "Employed – Part-time",
                "Self-employed",
                "Student",
                "Homemaker",
                "Retired",
                "Unemployed",
                "Other",
              ],
              onChanged: (val) => setState(() => employment = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: occupationController,
              labelText: 'Occupation',
              validator: (value) =>
                  (employment != "Unemployed" && (value?.isEmpty ?? true))
                  ? 'Required for employed users'
                  : null,
            ),

            SectionHeader(
              title: "Socioeconomic and Family Information",
              icon: Icons.family_restroom,
              required: true,
            ),
            AppDropdown(
              label: "Monthly Family Income (INR)",
              value: income,
              items: const [
                "< ₹10,000",
                "₹10,000 – ₹25,000",
                "₹25,001 – ₹50,000",
                "₹50,001 – ₹1,00,000",
                "> ₹1,00,000",
                "Prefer not to say",
              ],
              onChanged: (val) => setState(() => income = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppDropdown(
              label: "Type of Residence",
              value: residence,
              items: const [
                "Own house",
                "Rented house",
                "Hostel/PG",
                "Temporary shelter",
                "No fixed residence",
              ],
              onChanged: (val) => setState(() => residence = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppDropdown(
              label: "Marital Status",
              value: maritalStatus,
              items: const [
                "Single",
                "Married",
                "Widowed",
                "Separated/Divorced",
              ],
              onChanged: (val) => setState(() => maritalStatus = val),
              validator: (val) => val == null ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            AppTextFormField(
              controller: householdSizeController,
              labelText: 'Number of people in household',
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Required';
                if (int.tryParse(value!) == null) return 'Enter valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            AppCheckboxGroup(
              label: "Do you live with:",
              options: const ["Spouse", "Children", "Parents", "Others"],
              selectedValues: coResidents,
              onChanged: (values) => setState(() => coResidents = values ?? []),
              validator: (values) => (values?.isEmpty ?? true)
                  ? 'Please select at least one option'
                  : null,
            ),
            const SizedBox(height: 12),
            AppRadioGroup(
              label: "Primary Mode of Transportation:",
              options: const [
                "Own Vehicle",
                "Public Transport",
                "Shared Vehicle",
                "Auto/Taxi",
                "Walking",
                "Other",
              ],
              value: transport,
              onChanged: (val) => setState(() => transport = val),
              validator: (val) => val == null ? 'Required' : null,
            ),

            SectionHeader(
              title: "Disability Screening",
              icon: Icons.accessibility_new,
              required: true,
            ),
            AppCheckboxGroup(
              label: "Do you have any of the following difficulties?",
              options: const [
                "Hearing difficulty",
                "Vision problems (even with glasses)",
                "Mobility issues (e.g., walking, stairs)",
                "Memory/concentration problems",
                "Difficulty bathing/dressing on your own",
                "Difficulty going out alone (e.g., to hospital/shop)",
                "None of the above",
              ],
              selectedValues: disability,
              onChanged: (values) => setState(() => disability = values ?? []),
              validator: (values) => (values?.isEmpty ?? true)
                  ? 'Please select at least one option'
                  : null,
            ),

            const SizedBox(height: 24),
            const Divider(),
            CheckboxListTile(
              title: Text(
                "I consent to participate in this demographic survey.",
                style: AppTextStyles.bodyText,
              ),
              value: true,
              onChanged: null,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
            ),

            const SizedBox(height: 32),
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
    return _formKey.currentState?.validate() ??
        false &&
            respondentIdentity != null &&
            country != null &&
            cityController.text.isNotEmpty &&
            districtController.text.isNotEmpty &&
            selectedState != null &&
            pincodeController.text.isNotEmpty &&
            gender != null &&
            ageController.text.isNotEmpty &&
            education != null &&
            employment != null &&
            income != null &&
            residence != null &&
            maritalStatus != null &&
            transport != null &&
            householdSizeController.text.isNotEmpty &&
            coResidents.isNotEmpty &&
            disability.isNotEmpty;
  }

  Future<void> _submitForm() async {
    if (!(_validateAllFields())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      final data = {
        "userId": widget.userId.toString(),
        "sessionId": widget.sessionId,
        "startedAt": now.toIso8601String(),
        "completedAt": now.toIso8601String(),
        "respondentIdentity": respondentIdentity,
        "address": {
          "country": country,
          "city": cityController.text.trim(),
          "district": districtController.text.trim(),
          "state": selectedState,
          "pincode": pincodeController.text.trim(),
        },
        "personal": {
          "gender": gender,
          "age": ageController.text.trim(),
          "education": education,
          "employment": employment,
          "occupation": occupationController.text.trim(),
        },
        "socioeconomic": {
          "income": income,
          "residence": residence,
          "maritalStatus": maritalStatus,
          "householdSize": householdSizeController.text.trim(),
          "coResidents": coResidents,
          "transport": transport,
        },
        "disability": disability,
        "consented": true,
        "date": DateFormat('yyyy-MM-dd').format(now),
      };
      final progressData = {
        'respondentIdentity': respondentIdentity,
        'city': cityController.text.trim(),
        'district': districtController.text.trim(),
        'state': selectedState,
        'pincode': pincodeController.text.trim(),
        'country': country,
        'gender': gender,
        'age': ageController.text.trim(),
        'education': education,
        'employment': employment,
        'occupation': occupationController.text.trim(),
        'income': income,
        'residence': residence,
        'maritalStatus': maritalStatus,
        'householdSize': householdSizeController.text.trim(),
        'coResidents': coResidents,
        'transport': transport,
        'disability': disability,
      };

      // Save to backend for resume
      await ApiService.saveSessionProgress(
        userId: widget.userId.toString(),
        sessionId: widget.sessionId,
        currentPage: '/confounder-questionnaire',
        progressData: progressData,
      );

      final response = await ApiService.submitDemographics(data);

      if (response['success'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfounderQuestionnairePage(
              userId: widget.userId.toString(),
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
      debugPrint('Error in demographics submission: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    cityController.dispose();
    districtController.dispose();
    pincodeController.dispose();
    ageController.dispose();
    occupationController.dispose();
    householdSizeController.dispose();
    super.dispose();
  }
}
