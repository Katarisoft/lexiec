import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../app/app_routes.dart';
import '../../data/models/local_library.dart';
import '../common/format.dart';
import '../common/widgets/state_views.dart';
import 'local_library_controller.dart';

/// Favoritos guardados en el dispositivo. Funciona sin conexión: muestra
/// la copia guardada con su fecha.
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  Future<void> _confirmDeleteAll(
    BuildContext context,
    LocalLibraryController local,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Borrar datos locales'),
        content: const Text(
          'Se borrarán de este dispositivo todos tus favoritos y notas de esta '
          'cuenta. No se puede deshacer. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: const Key('delete-local-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await local.deleteAccountData();
  }

  @override
  Widget build(BuildContext context) {
    final LocalLibraryController local = Get.find();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis favoritos'),
        actions: [
          IconButton(
            key: const Key('delete-local'),
            tooltip: 'Borrar datos locales de esta cuenta',
            icon: const Icon(Icons.delete_sweep),
            onPressed: () => _confirmDeleteAll(context, local),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final error = local.error.value;
          if (error != null) return ErrorView(message: error);
          if (!local.isReady.value) {
            return const LoadingView(message: 'Cargando tus favoritos…');
          }
          if (local.favorites.isEmpty) {
            return const EmptyView(
              icon: Icons.star_border,
              message:
                  'Aún no tienes favoritos. Marca la estrella en una ficha para '
                  'guardar una copia en este dispositivo.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Copias guardadas en este dispositivo. El contenido '
                        'puede haber cambiado: abre la ficha para ver la '
                        'versión actual.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              for (final favorite in local.favorites)
                _FavoriteCard(favorite: favorite, local: local),
            ],
          );
        }),
      ),
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.favorite, required this.local});

  final FavoriteTopic favorite;
  final LocalLibraryController local;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final note = local.notes[favorite.topicId];
    return Card(
      key: Key('favorite-${favorite.topicId}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(favorite.title, style: text.titleSmall)),
                IconButton(
                  tooltip: 'Quitar de favoritos',
                  icon: const Icon(Icons.star),
                  onPressed: () => local.removeFavorite(favorite.topicId),
                ),
              ],
            ),
            Text(favorite.areaName, style: text.labelMedium),
            const SizedBox(height: 4),
            Text(
              favorite.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'Copia guardada el ${formatDate(favorite.savedAt)}',
              style: text.bodySmall,
            ),
            if (note != null) ...[
              const SizedBox(height: 4),
              Text('Mi nota: ${note.text}', style: text.bodySmall),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Get.toNamed<void>(
                  AppRoutes.topic,
                  arguments: favorite.topicId,
                ),
                child: const Text('Abrir ficha actual'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
