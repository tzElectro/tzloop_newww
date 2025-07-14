
class WLEDEffect {
  final int id;
  final String name;
  final String? description;
  final String? category;
  bool isExpanded = false;

  WLEDEffect({
    required this.id,
    required this.name,
    this.description,
    this.category,
    this.isExpanded = false,
  });

  factory WLEDEffect.fromJson(Map<String, dynamic> json) {
    return WLEDEffect(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      isExpanded: json['isExpanded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      'isExpanded': isExpanded,
    };
  }
}

class EffectParameter {
  final String name;
  final int min;
  final int max;
  final int defaultValue;
  final String description;

  const EffectParameter({
    required this.name,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.description,
  });

  factory EffectParameter.fromJson(Map<String, dynamic> json) {
    return EffectParameter(
      name: json['name'] ?? 'Parameter',
      min: json['min'] ?? 0,
      max: json['max'] ?? 255,
      defaultValue: json['default'] ?? 128,
      description: json['description'] ?? '',
    );
  }
} 