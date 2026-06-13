class AutoCategorizationService {
  // Simple keyword-based rules
  // In a real app, these would be loaded from a database table 'Rules'
  static final Map<String, String> _rules = {
    'uber': 'Travel',
    'lyft': 'Travel',
    'hotel': 'Lodging',
    'airbnb': 'Lodging',
    'starbucks': 'Meals & Entertainment',
    'mcdonalds': 'Meals & Entertainment',
    'aws': 'Software Subscription',
    'google': 'Software Subscription',
    'adobe': 'Software Subscription',
    'upwork': 'Contractors',
  };

  /// Returns a suggested category name if a keyword matches.
  String? suggestCategory(String description) {
    final lowerDesc = description.toLowerCase();

    for (var entry in _rules.entries) {
      if (lowerDesc.contains(entry.key)) {
        return entry.value;
      }
    }

    return null;
  }
}
