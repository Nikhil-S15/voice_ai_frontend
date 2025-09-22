import 'package:flutter/material.dart';
import 'package:voice_ai_app/api_service.dart';
import 'package:voice_ai_app/models/vhi_question.dart';
import 'package:voice_ai_app/screens/thankyou/thankyou_page.dart';
import 'package:voice_ai_app/theme/app_colors.dart';
import 'package:voice_ai_app/theme/app_text_styles.dart';
import 'package:voice_ai_app/widgets/app_buttons.dart';
import 'package:voice_ai_app/widgets/section_header.dart';

class VHIAssessmentPage extends StatefulWidget {
  final String userId;
  final String sessionId;
  final String language;

  const VHIAssessmentPage({
    Key? key,
    required this.userId,
    required this.sessionId,
    required this.language,
  }) : super(key: key);

  @override
  State<VHIAssessmentPage> createState() => _VHIAssessmentPageState();
}

class _VHIAssessmentPageState extends State<VHIAssessmentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  late final DateTime _startTime;

  // Map of question number to score (0-4)
  final Map<int, int?> _scores = {};

  // VHI Questions data - English version
  final List<VHIQuestion> _englishQuestions = [
    // Functional Subscale (1-10)
    VHIQuestion(
      number: 1,
      text: "My voice makes it difficult for people to hear me.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 2,
      text: "People have difficulty understanding me in a noisy room.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 3,
      text: "My voice difficulties restrict personal and social life.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 4,
      text: "I feel left out of conversations because of my voice.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 5,
      text: "My voice problem causes me to avoid groups of people.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 6,
      text: "People ask me to repeat myself when speaking face-to-face.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 7,
      text: "I use the telephone less often than I would like.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 8,
      text: "My voice problem limits my communication with family and friends.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 9,
      text: "I feel handicapped because of my voice.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 10,
      text:
          "My voice problem makes it difficult for me to express myself emotionally.",
      subscale: "functional",
    ),

    // Physical Subscale (11-20)
    VHIQuestion(
      number: 11,
      text: "I run out of air when I talk.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 12,
      text: "The sound of my voice varies throughout the day.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 13,
      text: "People have difficulty hearing me.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 14,
      text: "I use a great deal of effort to speak.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 15,
      text: "My voice is weak or breathy.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 16,
      text: "I experience pain or discomfort when speaking.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 17,
      text: "My voice 'gives out' on me in the middle of speaking.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 18,
      text: "I feel as though I have to strain to produce voice.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 19,
      text: "I find it difficult to project my voice.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 20,
      text: "My voice is hoarse or rough.",
      subscale: "physical",
    ),

    // Emotional Subscale (21-30)
    VHIQuestion(
      number: 21,
      text: "I am tense when talking with others because of my voice.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 22,
      text: "People seem irritated by my voice.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 23,
      text: "I find other people don't understand my voice problem.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 24,
      text: "My voice problem upsets me.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 25,
      text: "I am less outgoing because of my voice problem.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 26,
      text: "My voice makes me feel incompetent.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 27,
      text: "I feel annoyed when people ask me to repeat.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 28,
      text: "I feel embarrassed when people ask me to repeat.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 29,
      text: "My voice makes me feel frustrated.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 30,
      text: "I am depressed because of my voice problem.",
      subscale: "emotional",
    ),
  ];

  // VHI Questions data - Malayalam version
  final List<VHIQuestion> _malayalamQuestions = [
    // Functional Subscale (1-10)
    VHIQuestion(
      number: 1,
      text:
          "എന്റെ ശബ്ദം മൂലം ആളുകൾക്ക് എന്നെ കേൾക്കാൻ ബുദ്ധിമുട്ട് ഉണ്ടാകുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 2,
      text:
          "ഒച്ചപ്പാട് ഉള്ള മുറിയിൽ ആളുകൾക്ക് എന്നെ മനസ്സിലാക്കാൻ ബുദ്ധിമുട്ട് ഉണ്ടാകുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 3,
      text:
          "എന്റെ ശബ്ദ പ്രശ്നങ്ങൾ വ്യക്തിപരമായും സാമൂഹികവുമായ ജീവിതത്തെ പരിമിതപ്പെടുത്തുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 4,
      text:
          "എന്റെ ശബ്ദം മൂലം സംഭാഷണങ്ങളിൽ നിന്ന് ഒഴിവാക്കപ്പെടുന്നതായി ഞാൻ അനുഭവിക്കുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 5,
      text:
          "എന്റെ ശബ്ദ പ്രശ്നം മൂലം ആളുകളുടെ സമൂഹങ്ങൾ ഒഴിവാക്കാൻ ഞാൻ നിർബന്ധിതനാകുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 6,
      text:
          "മുഖാമുഖം സംസാരിക്കുമ്പോൾ ആളുകൾ എന്നോട് വീണ്ടും പറയാൻ ആവശ്യപ്പെടുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 7,
      text:
          "ഞാൻ ആഗ്രഹിക്കുന്നതിനേക്കാൾ കുറച്ച് തവണ മാത്രമേ ടെലിഫോൺ ഉപയോഗിക്കുന്നുള്ളൂ.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 8,
      text:
          "എന്റെ ശബ്ദ പ്രശ്നം കുടുംബാംഗങ്ങളും സുഹൃത്തുക്കളുമായുള്ള ആശയവിനിമയത്തെ പരിമിതപ്പെടുത്തുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 9,
      text: "എന്റെ ശബ്ദം മൂലം ഞാൻ വൈകല്യം അനുഭവിക്കുന്നു.",
      subscale: "functional",
    ),
    VHIQuestion(
      number: 10,
      text:
          "എന്റെ ശബ്ദ പ്രശ്നം മൂലം വൈകാരികമായി എന്നെത്തന്നെ പ്രകടിപ്പിക്കാൻ ബുദ്ധിമുട്ട് ഉണ്ടാകുന്നു.",
      subscale: "functional",
    ),

    // Physical Subscale (11-20)
    VHIQuestion(
      number: 11,
      text: "സംസാരിക്കുമ്പോൾ എനിക്ക് ശ്വാസം മുട്ടുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 12,
      text: "ദിവസം മുഴുവൻ എന്റെ ശബ്ദത്തിന്റെ ശബ്ദം വ്യത്യാസപ്പെടുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 13,
      text: "ആളുകൾക്ക് എന്നെ കേൾക്കാൻ ബുദ്ധിമുട്ട് ഉണ്ടാകുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 14,
      text: "സംസാരിക്കാൻ എനിക്ക് വളരെയധികം പരിശ്രമം ചെയ്യേണ്ടിവരുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 15,
      text: "എന്റെ ശബ്ദം ദുർബലമോ ശ്വാസമിക്തമോ ആണ്.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 16,
      text: "സംസാരിക്കുമ്പോൾ വേദനയോ അസ്വസ്ഥതയോ ഞാൻ അനുഭവിക്കുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 17,
      text: "സംസാരിക്കുമ്പോൾ എന്റെ ശബ്ദം ഇടയ്ക്ക് നിലക്കുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 18,
      text: "ശബ്ദം ഉണ്ടാക്കാൻ ഞാൻ ബലപ്രയോഗം ചെയ്യേണ്ടിവരുന്നതായി തോന്നുന്നു.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 19,
      text: "എന്റെ ശബ്ദം പ്രൊജക്റ്റ് ചെയ്യാൻ എനിക്ക് ബുദ്ധിമുട്ടാണ്.",
      subscale: "physical",
    ),
    VHIQuestion(
      number: 20,
      text: "എന്റെ ശബ്ദം കർശനമോ പരുക്കനോ ആണ്.",
      subscale: "physical",
    ),

    // Emotional Subscale (21-30)
    VHIQuestion(
      number: 21,
      text:
          "എന്റെ ശബ്ദം മൂലം മറ്റുള്ളവരോട് സംസാരിക്കുമ്പോൾ ഞാൻ പിരിമുറുക്കം അനുഭവിക്കുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 22,
      text: "എന്റെ ശബ്ദത്താൽ ആളുകൾക്ക് ശല്യം തോന്നുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 23,
      text:
          "മറ്റുള്ളവർ എന്റെ ശബ്ദ പ്രശ്നം മനസ്സിലാക്കുന്നില്ലെന്ന് ഞാൻ കണ്ടെത്തുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 24,
      text: "എന്റെ ശബ്ദ പ്രശ്നം എന്നെ അസ്വസ്ഥനാക്കുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 25,
      text: "എന്റെ ശബ്ദ പ്രശ്നം മൂലം ഞാൻ കുറച്ച് സാമൂഹികമാകുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 26,
      text: "എന്റെ ശബ്ദം എന്നെ അപ്രാപ്തനാണെന്ന് തോന്നിക്കുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 27,
      text:
          "ആളുകൾ എന്നോട് വീണ്ടും പറയാൻ ആവശ്യപ്പെടുമ്പോൾ എനിക്ക് ശല്യം തോന്നുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 28,
      text:
          "ആളുകൾ എന്നോട് വീണ്ടും പറയാൻ ആവശ്യപ്പെടുമ്പോൾ എനിക്ക് ലജ്ജ തോന്നുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 29,
      text: "എന്റെ ശബ്ദം എന്നെ നിരാശനാക്കുന്നു.",
      subscale: "emotional",
    ),
    VHIQuestion(
      number: 30,
      text: "എന്റെ ശബ്ദ പ്രശ്നം മൂലം ഞാൻ വിഷാദം അനുഭവിക്കുന്നു.",
      subscale: "emotional",
    ),
  ];

  List<VHIQuestion> get _questions {
    return widget.language == 'malayalam'
        ? _malayalamQuestions
        : _englishQuestions;
  }

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    // Initialize all scores to null (unanswered)
    for (var i = 1; i <= 30; i++) {
      _scores[i] = null;
    }
  }

  List<VHIQuestion> _getQuestionsBySubscale(String subscale) =>
      _questions.where((q) => q.subscale == subscale).toList();

  Widget _buildQuestion(VHIQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${question.number}. ${question.text}",
          style: AppTextStyles.bodyText,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildScoreOption(
              question.number,
              0,
              widget.language == 'malayalam' ? "ഒരിക്കലും\nഇല്ല" : "Never",
            ),
            _buildScoreOption(
              question.number,
              1,
              widget.language == 'malayalam'
                  ? "ഏറെക്കുറെ\nഇല്ല"
                  : "Almost\nNever",
            ),
            _buildScoreOption(
              question.number,
              2,
              widget.language == 'malayalam' ? "ചിലപ്പോൾ" : "Sometimes",
            ),
            _buildScoreOption(
              question.number,
              3,
              widget.language == 'malayalam'
                  ? "ഏറെക്കുറെ\nഎപ്പോഴും"
                  : "Almost\nAlways",
            ),
            _buildScoreOption(
              question.number,
              4,
              widget.language == 'malayalam' ? "എപ്പോഴും" : "Always",
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Divider(height: 1),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildScoreOption(int questionNumber, int score, String label) {
    final isSelected = _scores[questionNumber] == score;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            setState(() {
              _scores[questionNumber] = score;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodyText.copyWith(
            fontSize: 10,
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscaleSection(String title, List<VHIQuestion> questions) {
    String localizedTitle = title;
    if (widget.language == 'malayalam') {
      if (title == 'Functional Subscale') {
        localizedTitle = 'ഫങ്ഷണൽ സബ്സ്കെയിൽ';
      } else if (title == 'Physical Subscale') {
        localizedTitle = 'ഫിസിക്കൽ സബ്സ്കെയിൽ';
      } else if (title == 'Emotional Subscale') {
        localizedTitle = 'ഇമോഷണൽ സബ്സ്കെയിൽ';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: localizedTitle, icon: _getSubscaleIcon(title)),
        const SizedBox(height: 16),
        ...questions.map(_buildQuestion).toList(),
      ],
    );
  }

  IconData _getSubscaleIcon(String title) {
    switch (title) {
      case 'Functional Subscale':
        return Icons.people;
      case 'Physical Subscale':
        return Icons.health_and_safety;
      case 'Emotional Subscale':
        return Icons.emoji_emotions;
      default:
        return Icons.help;
    }
  }

  bool _validateForm() => !_scores.values.any((v) => v == null);

  Future<void> _submitForm() async {
    if (!_validateForm()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.language == 'malayalam'
                ? 'ദയവായി എല്ലാ ചോദ്യങ്ങൾക്കും ഉത്തരം നൽകുക'
                : 'Please answer all questions',
          ),
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Build subscale maps
      final functionalScores = <String, int>{};
      final physicalScores = <String, int>{};
      final emotionalScores = <String, int>{};

      for (var q in _questions) {
        final score =
            _scores[q.number] ?? 0; // Handle null values by providing default 0
        final key = 'q${q.number}';
        if (q.subscale == 'functional')
          functionalScores[key] = score;
        else if (q.subscale == 'physical')
          physicalScores[key] = score;
        else
          emotionalScores[key] = score;
      }

      // Calculate subscores and total - using null-safe approach
      final functionalSubscore = functionalScores.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0), // Handle potential null values
      );
      final physicalSubscore = physicalScores.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0), // Handle potential null values
      );
      final emotionalSubscore = emotionalScores.values.fold<int>(
        0,
        (a, b) => a + (b ?? 0), // Handle potential null values
      );
      final totalScore =
          functionalSubscore + physicalSubscore + emotionalSubscore;

      final payload = {
        'userId': widget.userId,
        'sessionId': widget.sessionId,
        'functionalScores': functionalScores,
        'physicalScores': physicalScores,
        'emotionalScores': emotionalScores,
        'language': widget.language,
        'totalScore': totalScore,
        'functionalSubscore': functionalSubscore,
        'physicalSubscore': physicalSubscore,
        'emotionalSubscore': emotionalSubscore,
        'durationMinutes': DateTime.now().difference(_startTime).inMinutes,
      };

      // Direct VHI submission without connection test
      final response = await ApiService.submitVHI(payload);

      if (response['success'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ThankYouPage()),
        );
      } else {
        String errorMessage = response['message'] ?? 'Submission failed';

        // Include validation errors if available
        if (response['errors'] != null) {
          final errors = List<String>.from(response['errors']);
          errorMessage += '\n${errors.join('\n')}';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: Duration(seconds: 5)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMalayalam = widget.language == 'malayalam';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          isMalayalam
              ? 'വോയ്സ് ഹാൻഡികാപ്പ് ഇൻഡെക്സ് (VHI)'
              : 'Voice Handicap Index (VHI)',
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
            // Instructions
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMalayalam ? 'നിർദ്ദേശങ്ങൾ:' : 'Instructions:',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isMalayalam
                          ? 'ഈ പ്രസ്താവനകൾ നിങ്ങളുടെ ശബ്ദ പ്രശ്നം ദൈനംദിന പ്രവർത്തനങ്ങളെ എങ്ങനെ സ്വാധീനിക്കുന്നു എന്ന് വിവരിക്കുന്നു. '
                              'ഓരോ അംഗത്തെയും നിങ്ങൾ എത്ര തവണ അനുഭവിക്കുന്നു എന്ന് ഉചിതമായ നമ്പർ തിരഞ്ഞെടുത്ത് സൂചിപ്പിക്കുക.'
                          : 'These statements describe how your voice problem influences your daily activities. '
                              'Please indicate how frequently you experience each item by selecting the appropriate number.',
                      style: AppTextStyles.bodyText,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isMalayalam ? 'സ്കോറിംഗ്:' : 'Scoring:',
                      style: AppTextStyles.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isMalayalam
                          ? '0 = ഒരിക്കലും ഇല്ല, 1 = ഏറെക്കുറെ ഇല്ല, 2 = ചിലപ്പോൾ, 3 = ഏറെക്കുറെ എപ്പോഴും, 4 = എപ്പോഴും'
                          : '0 = Never, 1 = Almost Never, 2 = Sometimes, 3 = Almost Always, 4 = Always',
                      style: AppTextStyles.bodyText,
                    ),
                  ],
                ),
              ),
            ),

            // Questions Sections
            _buildSubscaleSection(
              'Functional Subscale',
              _getQuestionsBySubscale('functional'),
            ),
            _buildSubscaleSection(
              'Physical Subscale',
              _getQuestionsBySubscale('physical'),
            ),
            _buildSubscaleSection(
              'Emotional Subscale',
              _getQuestionsBySubscale('emotional'),
            ),

            const SizedBox(height: 24),
            // Consent
            const Divider(),
            CheckboxListTile(
              title: Text(
                isMalayalam
                    ? "എല്ലാ ചോദ്യങ്ങൾക്കും സത്യസന്ധമായി ഉത്തരം നൽകിയിട്ടുണ്ടെന്ന് ഞാൻ സ്ഥിരീകരിക്കുന്നു."
                    : "I confirm that I have answered all questions truthfully.",
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
                  : Text(
                      isMalayalam
                          ? 'VHI അസസ്മെന്റ് സമർപ്പിക്കുക'
                          : 'Submit VHI Assessment',
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
