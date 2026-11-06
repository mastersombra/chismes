class Country {
  final String id;
  final String code;
  final String name;

  const Country({
    required this.id,
    required this.code,
    required this.name,
  });

  /// Crea un Country desde JSON de Supabase
  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
    );
  }

  /// Convierte a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
    };
  }
}
