import 'package:injectable/injectable.dart';

import '../../../../core/result/result.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/logging/logging.dart';
import '../../domain/entities/gossip.dart';
import '../../domain/entities/create_gossip_input.dart';
import '../../domain/entities/gossip_query.dart';
import '../../domain/entities/report_reason.dart';
import '../../domain/repositories/gossip_repository.dart';
import '../datasources/gossip_remote_data_source.dart';
import '../datasources/gossip_local_data_source.dart';
import '../models/gossip_model.dart';

@Singleton(as: GossipRepository)
class GossipRepositoryImpl implements GossipRepository {
  final GossipRemoteDataSource remoteDataSource;
  final GossipLocalDataSource localDataSource;
  final AppLogger _logger;

  GossipRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required AppLogger logger,
  }) : _logger = logger;

  @override
  Future<Result<Failure, List<Gossip>>> getGossips(GossipQuery query) async {
    try {
      // Intentar obtener datos del remoto con filtros
      final remoteModels = await remoteDataSource.getGossips(query);

      // Guardar en local para caché
      await localDataSource.saveAll(remoteModels);

      final gossips = remoteModels.map((model) => model.toEntity()).toList();
      return Result.success(gossips);
    } catch (error) {
      // Si falla el remoto, intentar obtener del local
      try {
        final localModels = await localDataSource.getAll();

        // ✅ FIX P6-3: Aplicar filtros de GossipQuery al caché
        final filteredModels = _applyQueryFilters(localModels, query);

        final gossips = filteredModels.map((model) => model.toEntity()).toList();
        return Result.success(gossips);
      } catch (localError) {
        return Result.failure(ErrorHandler.handleError(localError));
      }
    }
  }

  /// Aplica filtros de GossipQuery a una lista de modelos en memoria
  ///
  /// Esto es necesario porque el caché local retorna TODOS los gossips,
  /// pero el usuario puede estar filtrando por ciudad/región/país.
  List<GossipModel> _applyQueryFilters(List<GossipModel> models, GossipQuery query) {
    var filtered = models.where((model) {
      // Filtrar por ubicación
      if (query.countryId != null && model.countryId != query.countryId) {
        return false;
      }
      if (query.regionId != null && model.regionId != query.regionId) {
        return false;
      }
      if (query.cityId != null && model.cityId != query.cityId) {
        return false;
      }

      // Filtrar por status
      if (query.status != null && model.status != query.status!.value) {
        return false;
      }

      // Filtrar por visibility
      if (query.visibility != null && model.visibility != query.visibility!.value) {
        return false;
      }

      return true;
    }).toList();

    // Ordenar según query.orderBy
    filtered.sort((a, b) {
      int comparison;
      switch (query.orderBy) {
        case 'createdAt':
          comparison = a.createdAt.compareTo(b.createdAt);
          break;
        case 'modifiedAt':
          comparison = (a.modifiedAt ?? a.createdAt).compareTo(b.modifiedAt ?? b.createdAt);
          break;
        case 'viewCount':
          comparison = a.viewCount.compareTo(b.viewCount);
          break;
        default:
          comparison = a.createdAt.compareTo(b.createdAt);
      }

      // Invertir si es descendente
      return query.descending ? -comparison : comparison;
    });

    // Aplicar límite
    if (filtered.length > query.limit) {
      filtered = filtered.sublist(0, query.limit);
    }

    return filtered;
  }


  @override
  Future<Result<Failure, Gossip>> createWithImage(
    CreateGossipInput input,
    String? imageBase64,
  ) async {
    try {
      // Crear en el remoto con imagen (atómico)
      // La Edge Function hace TODO:
      // - Upload a cuarentena
      // - Validación MIME, dimensiones
      // - Moderación
      // - Mover a público si aprueba
      // - INSERT gossip con storage_path
      final model = await remoteDataSource.createWithImage(input, imageBase64);

      // Guardar en local (no bloqueante)
      try {
        await localDataSource.save(model);
      } catch (cacheError, stackTrace) {
        // Log del error de caché pero no fallar la operación
        _logger.w(
          'Cache local falló pero remoto tuvo éxito',
          error: cacheError,
          stackTrace: stackTrace,
          context: {
            'gossipId': model.id,
            'operation': 'save_to_cache_after_create_with_image',
          },
        );
      }

      return Result.success(model.toEntity());
    } catch (error) {
      return Result.failure(ErrorHandler.handleError(error));
    }
  }

  @override
  Future<Result<Failure, void>> reportGossip({
    required String gossipId,
    required ReportReason reason,
    String? details,
  }) async {
    try {
      await remoteDataSource.reportGossip(
        gossipId: gossipId,
        reason: reason,
        details: details,
      );

      return Result.success(null);
    } catch (error) {
      return Result.failure(ErrorHandler.handleError(error));
    }
  }
}
