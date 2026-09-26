import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/app_list_item.dart';
import '../providers/apps_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_list_tile.dart';
import '../widgets/block_note_dialog.dart';
import '../widgets/category_filter_chips.dart';
import '../widgets/category_picker_sheet.dart';
import '../widgets/glass_app_bar.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppsProvider>().loadApps();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const GlassAppBar(title: 'Apps'),
      body: Consumer<AppsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.loadError != null) {
            return _ErrorState(message: provider.loadError!, onRetry: provider.loadApps);
          }

          final apps = provider.filteredApps;
          final topInset = kToolbarHeight + MediaQuery.of(context).padding.top;

          return Column(
            children: [
              SizedBox(height: topInset + AppSpacing.xs),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.sm,
                  0,
                  AppSpacing.sm,
                  AppSpacing.xs,
                ),
                child: TextField(
                  onChanged: provider.setSearchQuery,
                  decoration: const InputDecoration(
                    hintText: 'Search apps',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              CategoryFilterChips(
                selected: provider.categoryFilter,
                onSelected: provider.setCategoryFilter,
              ),
              const SizedBox(height: AppSpacing.xs),
              Expanded(
                child: apps.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        itemCount: apps.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return AppListTile(
                            app: app,
                            onToggleBlocked: (value) => _handleToggle(context, provider, app, value),
                            onCategoryTap: () => _handleCategoryTap(context, provider, app),
                            onEditNote: () => _handleEditNote(context, provider, app),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleToggle(
    BuildContext context,
    AppsProvider provider,
    AppListItem app,
    bool turningOn,
  ) async {
    HapticFeedback.selectionClick();

    try {
      if (!turningOn) {
        await provider.setBlocked(app, isBlocked: false);
        return;
      }

      final note = await BlockNoteDialog.show(context, appName: app.appName);
      if (note == null) return;
      await provider.setBlocked(app, isBlocked: true, note: note);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update blocking for ${app.appName}.')),
        );
      }
    }
  }

  Future<void> _handleEditNote(
    BuildContext context,
    AppsProvider provider,
    AppListItem app,
  ) async {
    try {
      final note = await BlockNoteDialog.show(
        context,
        appName: app.appName,
        initialNote: app.blockNote,
      );
      if (note == null) return;
      await provider.setBlocked(app, isBlocked: true, note: note);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update blocking for ${app.appName}.')),
        );
      }
    }
  }

  Future<void> _handleCategoryTap(
    BuildContext context,
    AppsProvider provider,
    AppListItem app,
  ) async {
    final picked = await CategoryPickerSheet.show(context, current: app.resolvedCategory);
    if (picked == null) return;
    await provider.setCategoryOverride(app, picked);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'No apps match this search/filter.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
