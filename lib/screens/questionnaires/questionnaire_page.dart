import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuestionnaireScreen extends StatefulWidget {
  final int assignmentId;
  final String questionnaireType;
  final String language;
  final String userId;
  final VoidCallback onComplete;

  QuestionnaireScreen({
    required this.assignmentId,
    required this.questionnaireType,
    required this.language,
    required this.userId,
    required this.onComplete,
  });

  @override
  _QuestionnaireScreenState createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  Map<int, int> responses = {};
  bool isLoading = true;
  List<Map<String, dynamic>> questions = [];
  String? title;
  String? instructions;
  List<Map<String, dynamic>>? scale;

  @override
  void initState() {
    super.initState();
    _loadQuestionnaire();
  }

  Future<void> _loadQuestionnaire() async {
    try {
      final response = await http.post(
        Uri.parse('http://your-api-url/api/questionnaires/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assignmentId': widget.assignmentId,
          'questionnaireType': widget.questionnaireType,
          'language': widget.language,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          questions = List<Map<String, dynamic>>.from(
            data['data']['questions'],
          );
          title = data['data']['title'];
          instructions = data['data']['instructions'];
          scale = List<Map<String, dynamic>>.from(data['data']['scale']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load questionnaire');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading questionnaire: $e')),
      );
    }
  }

  Future<void> _submitQuestionnaire() async {
    try {
      final response = await http.post(
        Uri.parse('http://your-api-url/api/questionnaires/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'questionnaireId': 1, // You would get this from the start response
          'responses': responses,
        }),
      );

      if (response.statusCode == 200) {
        widget.onComplete();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit questionnaire: ${response.body}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting questionnaire: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(title ?? 'Questionnaire')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (instructions != null)
              Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Text(instructions!),
              ),
            ...questions.map((question) {
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${question['number']}. ${question['text']}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      if (scale != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: scale!.map((option) {
                            return ChoiceChip(
                              label: Text(option['label']),
                              selected:
                                  responses[question['number']] ==
                                  option['value'],
                              onSelected: (selected) {
                                setState(() {
                                  responses[question['number']] =
                                      option['value'];
                                });
                              },
                            );
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (responses.length == questions.length) {
                    _submitQuestionnaire();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please answer all questions')),
                    );
                  }
                },
                child: Text('Submit Questionnaire'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
