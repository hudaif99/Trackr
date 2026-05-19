import '../../../expenses/domain/entities/expense_entity.dart';

/// Local keyword-based categorization fallback.
///
/// Used when the Gemini API is unavailable. Maps common keywords to categories.
/// Keywords are intentionally broad and ordered from specific to general.
class LocalKeywordDataSource {
  static const Map<ExpenseCategory, List<String>> _keywords = {
    ExpenseCategory.food: [
      'kfc', 'mcdonald', 'swiggy', 'zomato', 'restaurant', 'cafe', 'coffee',
      'pizza', 'burger', 'lunch', 'dinner', 'breakfast', 'snack', 'food',
      'eat', 'meal', 'biscuit', 'chocolate', 'grocery', 'supermarket', 'bakery',
      'dhaba', 'hotel', 'biryani', 'chai', 'tea', 'juice', 'milk', 'vegetable',
    ],
    ExpenseCategory.travel: [
      'uber', 'ola', 'rapido', 'auto', 'taxi', 'cab', 'bus', 'train',
      'flight', 'airline', 'metro', 'railway', 'airport', 'toll', 'travel',
      'trip', 'hotel', 'booking', 'airbnb', 'makemytrip', 'irctc',
    ],
    ExpenseCategory.fuel: [
      'petrol', 'diesel', 'fuel', 'gas', 'cng', 'pump', 'station', 'refuel',
    ],
    ExpenseCategory.shopping: [
      'amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'zara', 'h&m',
      'shop', 'store', 'mall', 'market', 'cloth', 'shirt', 'shoes', 'bag',
      'watch', 'electronics', 'mobile', 'laptop', 'phone', 'gadget',
    ],
    ExpenseCategory.bills: [
      'electricity', 'water', 'gas bill', 'internet', 'wifi', 'broadband',
      'rent', 'emi', 'loan', 'insurance', 'maintenance', 'society', 'bill',
      'recharge', 'mobile bill', 'dth', 'subscription',
    ],
    ExpenseCategory.entertainment: [
      'netflix', 'prime', 'hotstar', 'spotify', 'youtube', 'movie', 'cinema',
      'pvr', 'inox', 'concert', 'event', 'game', 'play', 'fun', 'party',
      'outing', 'amusement', 'streaming',
    ],
    ExpenseCategory.health: [
      'doctor', 'hospital', 'clinic', 'medicine', 'pharmacy', 'medical',
      'health', 'gym', 'fitness', 'yoga', 'supplement', 'vitamin', 'lab',
      'test', 'scan', 'dentist', 'ayurveda',
    ],
    ExpenseCategory.education: [
      'school', 'college', 'university', 'course', 'class', 'tuition',
      'book', 'stationery', 'exam', 'fee', 'udemy', 'coursera', 'study',
      'training', 'certification', 'workshop',
    ],
  };

  /// Returns the best matching category for [description], or [other].
  ExpenseCategory categorize(String description) {
    final lower = description.toLowerCase();

    // Count keyword hits per category and return the best match
    ExpenseCategory? best;
    int bestScore = 0;

    for (final entry in _keywords.entries) {
      final score = entry.value.where((kw) => lower.contains(kw)).length;
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }

    return best ?? ExpenseCategory.other;
  }
}
