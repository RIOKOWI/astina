class LetterTypeModel {
  final int id;
  final String code;
  final String name;
  final String? description;
  final String? templatePath;
  final bool isActive;
  final List<LetterFieldModel>? fields;

  LetterTypeModel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.templatePath,
    this.isActive = true,
    this.fields,
  });

  factory LetterTypeModel.fromJson(Map<String, dynamic> json) {
    return LetterTypeModel(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      templatePath: json['template_path'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      fields: json['fields'] != null
          ? (json['fields'] as List<dynamic>)
                .map(
                  (e) => LetterFieldModel.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : null,
    );
  }

  String get fieldCountLabel {
    final count = fields?.length ?? 0;
    return count == 1 ? '1 kolom' : '$count kolom';
  }
}

class LetterFieldModel {
  final int id;
  final String fieldKey;
  final String label;
  final String fieldType;
  final bool isRequired;
  final int sortOrder;
  final List<String>? options;

  LetterFieldModel({
    required this.id,
    required this.fieldKey,
    required this.label,
    required this.fieldType,
    this.isRequired = false,
    this.sortOrder = 0,
    this.options,
  });

  factory LetterFieldModel.fromJson(Map<String, dynamic> json) {
    return LetterFieldModel(
      id: json['id'] as int,
      fieldKey: json['field_key'] as String,
      label: json['label'] as String,
      fieldType: json['field_type'] as String,
      isRequired: json['is_required'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 0,
      options: json['options'] != null
          ? List<String>.from(json['options'] as List)
          : null,
    );
  }
}
