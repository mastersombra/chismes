
import 'package:flutter/material.dart';
import '../../domain/entities/gossip.dart';
import '../controllers/add_gossip_controller.dart';
import '../states/add_gossip_state.dart';
import '../../../../core/error/error_messages.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/result/result.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/di/injection_container.dart';
import '../widgets/compact_location_selector.dart';
import '../widgets/location_change_dialog.dart';
import '../widgets/gossip_text_fields.dart';
import '../widgets/publish_as_selector.dart';
import '../widgets/image_picker_widget.dart';
import '../../../location/domain/entities/city.dart';
import '../../../location/domain/usecases/search_cities.dart';
import '../../../auth/presentation/widgets/email_verification_banner.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import 'package:chismes/core/l10n/l10n.dart';

class AddGossipScreen extends StatefulWidget {
  final AddGossipController controller;

  const AddGossipScreen({
    super.key,
    required this.controller,
  });

  @override
  State<AddGossipScreen> createState() => _AddGossipScreenState();
}

class _AddGossipScreenState extends State<AddGossipScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _subjectController;
  late final TextEditingController _contentController;
  final _authRepository = getIt<AuthRepository>();
  bool _isResendingEmail = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _contentController = TextEditingController();
    // NOTE: No llamar initialize() aquí - ya se llama en el constructor del controller
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _contentController.dispose();
    // El controller es gestionado por el padre que creó el screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {

        final state = widget.controller.state;

        return Scaffold(
          // ✅ OPTIMIZACIÓN: AppBar es invariante (no cambia nunca)
          // Usando el parámetro child, se construye UNA VEZ y se reutiliza
          appBar: child as PreferredSizeWidget,
          body: _buildBody(state),
        );
      },
      // ✅ child se construye UNA VEZ, no en cada rebuild
      child: AppBar(title: Text(context.l10n.gossipAddScreenTitle)),
    );
  }

  Widget _buildBody(AddGossipState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ubicación compacta con opción de cambiar
            CompactLocationSelector(
              locationText: widget.controller.locationDisplayText,
              onChangePressed: _showLocationChangeDialog,
              isLoading: widget.controller.locationManager.state.isLoading,
            ),
            const SizedBox(height: AppSpacing.lg),

            // Banner de verificación de email
            if (_authRepository.currentUser != null &&
                !_authRepository.currentUser!.emailVerified)
              EmailVerificationBanner(
                onResend: _resendVerificationEmail,
                isLoading: _isResendingEmail,
              ),

            // ✅ OPTIMIZADO: Solo reconstruye cuando cambia failure
            ValueListenableBuilder<Failure?>(
              valueListenable: widget.controller.failureNotifier,
              builder: (context, failure, child) {
                if (failure == null) return const SizedBox.shrink();

                // Usar mensaje personalizado del servidor si está disponible (ej: rate limiting)
                String message;
                if (failure is ServerFailure) {
                  message = failure.message ?? ErrorMessages.getMessage(context, failure.code);
                } else {
                  message = ErrorMessages.getMessage(context, failure.code);
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              message,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
            ),

            GossipTextFields(
              subjectController: _subjectController,
              contentController: _contentController,
              onSubjectChanged: widget.controller.updateSubject,
              onContentChanged: widget.controller.updateContent,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ✅ OPTIMIZADO: Solo reconstruye cuando cambia imagen o estado de upload
            ValueListenableBuilder<String?>(
              valueListenable: widget.controller.imageNotifier,
              builder: (context, imageUrl, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: widget.controller.isUploadingImageNotifier,
                  builder: (context, isUploading, child) {
                    return ImagePickerWidget(
                      imageUrl: imageUrl,
                      isUploading: isUploading,
                      onPickFromCamera: widget.controller.pickImageFromCamera,
                      onPickFromGallery: widget.controller.pickImageFromGallery,
                      onRemove: widget.controller.removeImage,
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            PublishAsSelector(
              state: state,
              onPublishAsChanged: widget.controller.setPublishedAs,
            ),
            const SizedBox(height: AppSpacing.xl),

            // ✅ OPTIMIZADO: Solo reconstruye cuando cambia isSubmitting
            ValueListenableBuilder<bool>(
              valueListenable: widget.controller.isSubmittingNotifier,
              builder: (context, isSubmitting, child) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              final gossip = await widget.controller.submit();
                              if (gossip != null && mounted) {
                                // Mostrar confirmación tras publicar en lugar de salida brusca
                                _showSuccessDialog(gossip);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : Text(
                            context.l10n.gossipAddScreenSubmitButton,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog(Gossip gossip) {
    final isPendingReview = gossip.status == GossipStatus.draft;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF2E7D32) // successLight
                  : const Color(0xFF66BB6A), // successDark
              size: 28,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(isPendingReview
                ? context.l10n.gossipAddScreenSuccessDialogTitlePending
                : context.l10n.gossipAddScreenSuccessDialogTitlePublished),
            ),
          ],
        ),
        content: Text(
          isPendingReview
              ? context.l10n.gossipAddScreenSuccessDialogContentPending
              : context.l10n.gossipAddScreenSuccessDialogContentPublished,
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Limpiar formulario para prevenir duplicados
              widget.controller.reset();
              _subjectController.clear();
              _contentController.clear();

              // Cerrar diálogo
              if (mounted) {
                Navigator.of(context).pop();
              }

              // ✅ FIX: NO hacer Navigator.pop() aquí
              // AddGossipScreen es una tab del BottomNavigationBar, no una pantalla modal.
              // Hacer pop() causaría que toda la navegación se cierre (pantalla negra).
              //
              // El formulario ya está limpio y listo para un nuevo chisme.
              // El usuario puede:
              // - Crear otro chisme (quedarse en esta tab)
              // - Cambiar a la tab Home para ver el chisme publicado
            },
            child: Text(context.l10n.gossipAddScreenSuccessDialogButton),
          ),
        ],
      ),
    );
  }

  /// Muestra el dialog para cambiar la ubicación
  ///
  /// **Opciones:**
  /// 1. Usar ubicación actual (GPS)
  /// 2. Selección manual con autocomplete
  Future<void> _resendVerificationEmail() async {
    setState(() => _isResendingEmail = true);

    final result = await _authRepository.resendVerificationEmail();

    if (!mounted) return;

    setState(() => _isResendingEmail = false);

    // Manejo de Result<Failure, void>
    switch (result) {
      case Success():
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.gossipAddScreenEmailVerificationResent),
            backgroundColor: Colors.green,
          ),
        );
      case ResultFailure(error: final failure):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorMessages.getMessage(context, failure.code)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  void _showLocationChangeDialog() {
    final searchCities = getIt<SearchCities>();

    showDialog(
      context: context,
      builder: (context) => AnimatedBuilder(
        animation: widget.controller.locationManager,
        builder: (context, child) {
          return LocationChangeDialog(
            state: widget.controller.locationManager.state,
            searchCities: searchCities,
            onUseCurrentLocation: () async {
              await widget.controller.autoDetectLocation();
            },
            onCountryChanged: (value) {
              if (value != null) {
                widget.controller.selectCountry(value);
              }
            },
            onRegionChanged: (value) {
              if (value != null) {
                widget.controller.selectRegion(value);
              }
            },
            onCityChanged: (City? city) {
              widget.controller.selectCity(city?.id);
            },
            onConfirm: () {
              // La ubicación ya fue guardada automáticamente en selectCity()
            },
            isLoadingGPS: widget.controller.locationManager.state.isDetectingLocation,
          );
        },
      ),
    );
  }
}
