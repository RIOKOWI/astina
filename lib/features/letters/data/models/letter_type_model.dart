class LetterTypeField {
  final int? id;
  final String fieldKey;
  final String label;
  final String fieldType;
  final bool isRequired;
  final int? sortOrder;

  const LetterTypeField({
    this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    required this.isRequired,
    this.sortOrder,
  });

  factory LetterTypeField.fromJson(Map<String, dynamic> json) {
    return LetterTypeField(
      id: json['id'] as int?,
      fieldKey: json['field_key'] as String,
      label: json['label'] as String,
      fieldType: json['field_type'] as String,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: json['sort_order'] as int?,
    );
  }
}

class LetterType {
  final int id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final List<LetterTypeField> fields;

  const LetterType({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
    required this.fields,
  });

  factory LetterType.fromJson(Map<String, dynamic> json) {
    return LetterType(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      fields:
          (json['fields'] as List<dynamic>?)
              ?.map((e) => LetterTypeField.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
