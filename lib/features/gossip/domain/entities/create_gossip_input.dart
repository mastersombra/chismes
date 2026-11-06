import 'package:equatable/equatable.dart';
import '../entities/gossip.dart';

/// Input DTO para crear un nuevo Gossip
class CreateGossipInput extends Equatable {
  final String countryId;
  final String regionId;
  final String cityId;
  final String subject;
  final String content;
  final String? audioUrl;
  final String? imageUrl;
  final PublishAs publishedAs;
  
  /// Clave única para idempotencia de la operación
  /// Previene duplicados cuando el usuario reenvía la misma solicitud
  final String idempotencyKey;

  const CreateGossipInput({
    required this.countryId,
    required this.regionId,
    required this.cityId,
    required this.subject,
    required this.content,
    this.audioUrl,
    this.imageUrl,
    required this.publishedAs,
    required this.idempotencyKey,
  });

  @override
  List<Object?> get props => [
    countryId,
    regionId,
    cityId,
    subject,
    content,
    audioUrl,
    imageUrl,
    publishedAs,
    idempotencyKey,
  ];
}
