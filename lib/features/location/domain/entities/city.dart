class City {
  final String id;
  final String regionId;
  final String name;

  const City({
    required this.id,
    required this.regionId,
    required this.name,
  });

  /// Crea un City desde JSON de Supabase
  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'] as String,
      regionId: json['region_id'] as String,
      name: json['name'] as String,
    );
  }

  /// Convierte a JSON para Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region_id': regionId,
      'name': name,
    };
  }
}
