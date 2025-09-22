import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/screens/demographics/demographics_form_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/app_input_fields.dart';
// import 'package:voice_ai_app/utils/progress_storage.dart';

class OnboardingPage extends StatefulWidget {
  final String selectedLanguage;

  const OnboardingPage({super.key, required this.selectedLanguage});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final String sessionId = const Uuid().v4();
  final _formKey = GlobalKey<FormState>();
  final userIdController = TextEditingController();
  final participantNameController = TextEditingController();
  final witnessNameController = TextEditingController();
  bool consentAccepted = false;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _restoreProgress();
  }

  Future<void> _restoreProgress() async {
    // After userId is known (for demo, use the controller or pass as argument)
    final userId = userIdController.text;
    if (userId.isEmpty) return;
    final result = await ApiService.fetchSessionProgress(userId, sessionId);
    if (result != null) {
      final progress = result['progressData'];
      setState(() {
        participantNameController.text = progress['participantName'] ?? '';
        witnessNameController.text = progress['witnessName'] ?? '';
        consentAccepted = progress['consentAccepted'] ?? false;
      });
      // Optionally jump if last page:
      if (result['currentPage'] != '/onboarding') {
        Navigator.pushReplacementNamed(context, result['currentPage']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          "Onboarding & Consent",
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Consent Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showConsentDialog(context),
                        child: const Icon(
                          Icons.assignment,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Study Consent Form",
                        style: AppTextStyles.headlineSmall.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Please read and agree to the consent form before proceeding",
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: consentAccepted,
                            onChanged: (value) {
                              setState(() {
                                consentAccepted = value ?? false;
                              });
                            },
                            activeColor: AppColors.primary,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _showConsentDialog(context),
                              child: Text(
                                "I have read and agree to the consent form",
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Participant Information
              Text(
                "Participant Information",
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: userIdController,
                labelText: 'MRD Number',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: participantNameController,
                labelText: 'Participant Name',
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                prefixIcon: const Icon(Icons.badge_outlined),
              ),
              const SizedBox(height: 16),

              AppTextFormField(
                controller: witnessNameController,
                labelText: 'Witness Name (if applicable)',
                prefixIcon: const Icon(Icons.people_outline),
              ),

              const SizedBox(height: 32),

              AppElevatedButton(
                onPressed: isLoading ? null : _submitForm,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit & Continue"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showConsentDialog(BuildContext context) async {
    bool localConsent = consentAccepted;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text("Consent Form"),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedLanguage == 'ml'
                        ? '''1. പഠനത്തിന്റെ ശീർഷകം  
"ഹെഡ് ആൻഡ് നെക്ക് ക്യാൻസർ രോഗികളുടെയും ആരോഗ്യവാന്മാരുടെയും ശബ്ദം ആക്കൂസ്റ്റിക് പരിശോധന മൊബൈൽ ആപ്ലിക്കേഷനിലൂടെ"

2. പഠനത്തിന്റെ ഉദ്ദേശ്യം  
ഈ പഠനം ശബ്ദത്തിലെ ആക്കൂസ്റ്റിക് സ്വഭാവങ്ങളെ വിശകലനം ചെയ്യുകയും വിവിധ ആരോഗ്യസ്ഥിതികളുമായി അതിന്റെ ബന്ധം കണ്ടെത്തുകയും ചെയ്യുന്നതിന് ആണ്. നിങ്ങൾ ഈ പഠനത്തിൽ പങ്കെടുക്കാൻ ക്ഷണിക്കപ്പെട്ടിരിക്കുന്നു. ഇത് പൂർണ്ണമായി സ്വച്ഛന്ദമാണ്, നിങ്ങളുടെ തിരഞ്ഞെടുപ്പിൽ നിങ്ങൾ ഏത് സമയത്തും പിന്മാറാൻ കഴിയും, അതിന് യാതൊരു ദോഷകരമായ പ്രതിഫലനങ്ങളും ഉണ്ടാകില്ല.

3. പ്രക്രിയ  
നിങ്ങൾ പങ്കെടുക്കാൻ സമ്മതിക്കുന്നുവെങ്കിൽ, ഈ മൊബൈൽ ആപ്ലിക്കേഷനിലൂടെ നിങ്ങളുടെ ശബ്ദ സാമ്പിളുകൾ ശേഖരിക്കുന്നതിന് നിങ്ങളോട് ആവശ്യപ്പെടപ്പെടും. ഈ പ്രക്രിയ ഏകദേശം 5 മിനിറ്റോളം സമയം എടുക്കും.

4. രഹസ്യത  
നിങ്ങളുടെ ഡാറ്റ ഗവേഷണ ആവശ്യങ്ങൾക്കായി മാത്രം ഉപയോഗിക്കുകയും പരമാരീതിയിലുള്ള രഹസ്യമായി സൂക്ഷിക്കുകയും ചെയ്യും.

5. ബന്ധപ്പെടുക  
പഠനത്തെക്കുറിച്ച് കൂടുതൽ വിവരങ്ങൾക്കോ സംശയങ്ങൾക്കോ വേണ്ടി, ദയവായി ഗവേഷണ സംഘത്തെയോ അനുബന്ധ വ്യക്തികളെ [research contact info] എന്ന വിലാസത്തിൽ ബന്ധപ്പെടുക.
'''
                        : '''1. Title of the Study
“Voice and Acoustic Monitoring for Head and Neck Cancer Patients and Healthy Individuals using a Mobile Application”

2. Purpose of the Study
You are invited to participate in a research study being conducted to analyze acoustic features of voice and its correlation with various health conditions. Your participation is voluntary and you may withdraw at any time without any consequences.

3. Procedures
If you agree to participate, you will be asked to provide voice samples through this mobile application. The process will take approximately 5 minutes.

4. Confidentiality
Your data will be kept confidential and used only for research purposes.

5. Contact
For any questions regarding the study, you may contact the research team at [research contact info].
''',
                    style: AppTextStyles.bodyMedium,
                  ),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: localConsent,
                        onChanged: (value) {
                          setState(() {
                            localConsent = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      const Text("I agree"),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  this.setState(() {
                    consentAccepted = localConsent;
                  });
                  Navigator.pop(context);
                },
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (!consentAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the consent form')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final userId = userIdController.text.trim();
      final onboardingData = {
        'userId': userId,
        'participantName': participantNameController.text.trim(),
        'witnessName': witnessNameController.text.trim().isEmpty
            ? null
            : witnessNameController.text.trim(),
        'consentAccepted': consentAccepted,
        'sessionId': sessionId,
      };

      // 1. Submit onboarding data as before
      final response = await ApiService.submitOnboardingData(onboardingData);

      if (response != null) {
        // 2. Save partial progress to backend for resume (NEW)
        final progressData = {
          'participantName': participantNameController.text.trim(),
          'witnessName': witnessNameController.text.trim(),
          'consentAccepted': consentAccepted,
        };

        await ApiService.saveSessionProgress(
          userId: userId,
          sessionId: sessionId,
          currentPage: '/demographics', // Adapt as needed
          progressData: progressData,
        );

        // 3. Navigate to next page as before
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DemographicsPage(userId: response, sessionId: sessionId),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit onboarding data')),
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
}
