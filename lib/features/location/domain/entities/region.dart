class Region {
  final String id;
  final String countryId;
  final String name;
  final String type;

  const Region({
    required this.id,
    required this.countryId,
    required this.name,
    required this.type,
  });

  /// Crea un Region desde JSON de Supabase
  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'] as String,
      countryId: json['country_id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  /// Convierte a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country_id': countryId,
      'name': name,
      'type': type,
    };
  }
}
