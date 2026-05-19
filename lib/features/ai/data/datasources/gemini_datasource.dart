import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

/// Calls the Gemini REST API to categorize an expense description.
class GeminiDataSource {
  final http.Client _client;

  const GeminiDataSource(this._client);

  Future<ExpenseCategory> categorize(String description) async {
    final url = Uri.parse(
      '${AppConstants.geminiBaseUrl}/${AppConstants.geminiModel}:generateContent'
      '?key=${AppConstants.geminiApiKey}',
    );

    final prompt = '''
You are an expense categorizer. Given an expense description, respond with exactly one word from the list below.

Categories: food, travel, shopping, bills, entertainment, health, fuel, education, other

Rules:
- Respond with ONLY one category word, lowercase, no punctuation.
- If unsure, respond with: other

Expense: "$description"
Category:''';

    final response = await _client
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': prompt}
                ]
              }
            ],
            'generationConfig': {
              'temperature': 0.1,
              'maxOutputTokens': 10,
            },
          }),
        )
        .timeout(AppConstants.networkTimeout);

    if (response.statusCode != 200) {
      throw AiException(message: 'Gemini API error: ${response.statusCode}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final text = (json['candidates'] as List?)
            ?.firstOrNull?['content']?['parts']
            ?.firstOrNull?['text'] as String? ??
        '';

    return ExpenseCategory.fromString(text.trim().toLowerCase());
  }
}
