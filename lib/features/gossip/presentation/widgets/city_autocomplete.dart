import 'package:flutter/material.dart';
import '../../../location/domain/entities/city.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_radius.dart';

/// TextField con autocomplete para búsqueda de ciudades
///
/// **Comportamiento:**
/// - Usuario escribe "Med" → Muestra "Medellín", "Medina", "Medellín del Ariari"
/// - Filtra en tiempo real (búsqueda local en memoria)
/// - Acepta búsqueda por coincidencia parcial (contains, no solo startsWith)
///
/// **Escalabilidad:**
/// - Funciona bien con 100-5,000 ciudades por región
/// - Para 10,000+ ciudades → migrar a búsqueda en servidor
class CityAutocomplete extends StatefulWidget {
  final List<City> cities;
  final City? selectedCity;
  final ValueChanged<City?> onCitySelected;
  final String? Function(String?)? validator;

  const CityAutocomplete({
    super.key,
    required this.cities,
    required this.onCitySelected,
    this.selectedCity,
    this.validator,
  });

  @override
  State<CityAutocomplete> createState() => _CityAutocompleteState();
}

class _CityAutocompleteState extends State<CityAutocomplete> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  List<City> _filteredCities = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.selectedCity?.name ?? '',
    );
    _filteredCities = widget.cities;

    // Listener para mostrar/ocultar sugerencias
    _focusNode.addListener(() {
      setState(() {
        _showSuggestions = _focusNode.hasFocus;
      });
    });
  }

  @override
  void didUpdateWidget(CityAutocomplete oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Si cambia la lista de ciudades (ej: cambió la región)
    if (oldWidget.cities != widget.cities) {
      _filteredCities = widget.cities;
      _controller.clear();
    }

    // Si cambia la ciudad seleccionada externamente
    if (oldWidget.selectedCity != widget.selectedCity) {
      _controller.text = widget.selectedCity?.name ?? '';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCities = widget.cities;
      } else {
        // Búsqueda case-insensitive por coincidencia parcial
        final lowerQuery = query.toLowerCase();
        _filteredCities = widget.cities.where((city) {
          return city.name.toLowerCase().contains(lowerQuery);
        }).toList();
      }
    });
  }

  void _onCityTapped(City city) {
    _controller.text = city.name;
    widget.onCitySelected(city);
    _focusNode.unfocus(); // Ocultar sugerencias
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TextField de búsqueda
        TextFormField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            labelText: 'Ciudad',
            hintText: 'Buscar ciudad...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      widget.onCitySelected(null);
                      _onSearchChanged('');
                    },
                  )
                : const Icon(Icons.search),
          ),
          onChanged: _onSearchChanged,
          validator: widget.validator,
        ),

        // Lista de sugerencias
        if (_showSuggestions && _filteredCities.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              shrinkWrap: true,
              itemCount: _filteredCities.length,
              itemBuilder: (context, index) {
                final city = _filteredCities[index];
                final isSelected = widget.selectedCity?.id == city.id;

                return ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.location_city,
                    size: 20,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  title: Text(
                    city.name,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  trailing: isSelected ? const Icon(Icons.check, size: 20) : null,
                  onTap: () => _onCityTapped(city),
                );
              },
            ),
          ),

        // Mensaje si no hay resultados
        if (_showSuggestions && _filteredCities.isEmpty && _controller.text.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'No se encontraron ciudades con "${_controller.text}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
