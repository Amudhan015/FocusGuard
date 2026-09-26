import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../models/focus_session.dart';
import '../models/session_template.dart';
import '../providers/session_provider.dart';
import '../repositories/templates_repository.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../widgets/template_card.dart';
import '../widgets/timer_display.dart';
import '../screens/proof_flow_screen.dart';

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  SessionMode _selectedMode = SessionMode.pomodoro;
  int _focusMinutes = 25;
  int _shortBreakMinutes = 5;
  int _longBreakMinutes = 15;
  int _sessionsBeforeLongBreak = 4;
  bool _saveAsTemplate = false;

  final _subjectController = TextEditingController(text: 'General');
  final _intentionController = TextEditingController();
  final _templateNameController = TextEditingController();

  final TemplatesRepository _templatesRepository = TemplatesRepository();

  @override
  void initState() {
    super.initState();
    _templatesRepository.init();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _intentionController.dispose();
    _templateNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus'),
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: SafeArea(
        child: Consumer<SessionProvider>(
          builder: (context, provider, _) {
            if (provider.hasActiveSession) {
              return _ActiveSessionView(provider: provider);
            }
            return _buildSetupView(context);
          },
        ),
      ),
    );
  }

  Widget _buildSetupView(BuildContext context) {
    final templates = _templatesRepository.getAllTemplates();
    final pending = DatabaseService.instance.getPendingClosureSessions();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        if (pending.isNotEmpty) ...[
          _PendingClosureBanner(pendingSessions: pending),
          const SizedBox(height: AppSpacing.lg),
        ],

        ElevatedButton.icon(
          onPressed: () => context.read<SessionProvider>().startQuickFocus(),
          icon: const Icon(Icons.bolt, size: 20),
          label: const Text('Quick Focus Now (25 min)'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        if (templates.isNotEmpty) ...[
          Text(
            'Templates',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                final template = templates[index];
                return TemplateCard(
                  template: template,
                  onTap: () => _startFromTemplate(template),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        Text(
          'Custom session',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildCustomForm(context),
      ],
    );
  }

  Widget _buildCustomForm(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppShape.borderRadius,
        side: BorderSide(color: Theme.of(context).colorScheme.outline, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SegmentedButton<SessionMode>(
              segments: const [
                ButtonSegment(
                  value: SessionMode.pomodoro,
                  label: Text('Pomodoro'),
                ),
                ButtonSegment(
                  value: SessionMode.deepFocus,
                  label: Text('Deep Focus'),
                ),
              ],
              selected: {_selectedMode},
              onSelectionChanged: (selection) {
                setState(() => _selectedMode = selection.first);
              },
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.comfortable,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            _StepperRow(
              label: _selectedMode == SessionMode.pomodoro
                  ? 'Focus minutes'
                  : 'Duration (minutes)',
              value: _focusMinutes,
              min: 5,
              max: 180,
              step: 5,
              onChanged: (v) => setState(() => _focusMinutes = v),
            ),

            if (_selectedMode == SessionMode.pomodoro) ...[
              _StepperRow(
                label: 'Short break minutes',
                value: _shortBreakMinutes,
                min: 1,
                max: 30,
                step: 1,
                onChanged: (v) => setState(() => _shortBreakMinutes = v),
              ),
              _StepperRow(
                label: 'Long break minutes',
                value: _longBreakMinutes,
                min: 5,
                max: 60,
                step: 5,
                onChanged: (v) => setState(() => _longBreakMinutes = v),
              ),
              _StepperRow(
                label: 'Sessions before long break',
                value: _sessionsBeforeLongBreak,
                min: 2,
                max: 8,
                step: 1,
                onChanged: (v) => setState(() => _sessionsBeforeLongBreak = v),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject / tag',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _intentionController,
              decoration: const InputDecoration(
                labelText: 'Intention (optional)',
                hintText: 'e.g. "Finish calculus homework"',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Save as a reusable template',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                Switch(
                  value: _saveAsTemplate,
                  onChanged: (v) => setState(() => _saveAsTemplate = v),
                ),
              ],
            ),
            if (_saveAsTemplate)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextField(
                  controller: _templateNameController,
                  decoration: const InputDecoration(
                    labelText: 'Template name',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ),
              ),

            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _startCustomSession,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                elevation: 0,
              ),
              child: const Text('Start Session'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startFromTemplate(SessionTemplate template) async {
    final provider = context.read<SessionProvider>();
    if (template.mode == SessionMode.pomodoro) {
      await provider.startPomodoro(
        focusMinutes: template.focusMinutes,
        shortBreakMinutes: template.shortBreakMinutes,
        longBreakMinutes: template.longBreakMinutes,
        sessionsBeforeLongBreak: template.sessionsBeforeLongBreak,
        subjectTag: template.subjectTag,
        templateId: template.id,
      );
    } else {
      await provider.startDeepFocus(
        minutes: template.focusMinutes,
        subjectTag: template.subjectTag,
        templateId: template.id,
      );
    }
  }

  Future<void> _startCustomSession() async {
    final subjectTag = _subjectController.text.trim().isEmpty
        ? 'General'
        : _subjectController.text.trim();
    final intention = _intentionController.text.trim();

    String? templateId;
    if (_saveAsTemplate && _templateNameController.text.trim().isNotEmpty) {
      final template = SessionTemplate(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _templateNameController.text.trim(),
        mode: _selectedMode,
        focusMinutes: _focusMinutes,
        shortBreakMinutes: _shortBreakMinutes,
        longBreakMinutes: _longBreakMinutes,
        sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
        subjectTag: subjectTag,
        createdAt: DateTime.now(),
      );
      await _templatesRepository.saveTemplate(template);
      if (!mounted) return;
      templateId = template.id;
    }

    final provider = context.read<SessionProvider>();
    if (_selectedMode == SessionMode.pomodoro) {
      await provider.startPomodoro(
        focusMinutes: _focusMinutes,
        shortBreakMinutes: _shortBreakMinutes,
        longBreakMinutes: _longBreakMinutes,
        sessionsBeforeLongBreak: _sessionsBeforeLongBreak,
        subjectTag: subjectTag,
        intentionText: intention.isEmpty ? null : intention,
        templateId: templateId,
      );
    } else {
      await provider.startDeepFocus(
        minutes: _focusMinutes,
        subjectTag: subjectTag,
        intentionText: intention.isEmpty ? null : intention,
        templateId: templateId,
      );
    }
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            iconSize: 20,
            onPressed: value > min ? () => onChanged(value - step) : null,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            iconSize: 20,
            onPressed: value < max ? () => onChanged(value + step) : null,
            constraints: const BoxConstraints(),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _PendingClosureBanner extends StatelessWidget {
  const _PendingClosureBanner({
    required this.pendingSessions,
  });

  final List<FocusSession> pendingSessions;

  @override
  Widget build(BuildContext context) {
    if (pendingSessions.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        if (pendingSessions.length == 1) {
          // Directly navigate to the single pending session's proof flow
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProofFlowScreen(sessionId: pendingSessions.first.id),
            ),
          );
        } else {
          // Show session selection dialog for multiple pending sessions
          showDialog<FocusSession>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Select Session for Proof',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingSessions.length,
                  itemBuilder: (context, index) {
                    final session = pendingSessions[index];
                    return ListTile(
                      leading: session.photoPath != null
                          ? Icon(Icons.photo, color: colorScheme.primary)
                          : Icon(Icons.image_not_supported,
                              color: colorScheme.onSurface.withValues(alpha: 0.6)),
                      title: Text(session.subjectTag),
                      subtitle: Text(
                        'Started: ${session.startTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProofFlowScreen(sessionId: session.id),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colorScheme.tertiary.withValues(alpha: 0.08),
          borderRadius: AppShape.borderRadius,
          border: Border.all(
            color: colorScheme.tertiary.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: colorScheme.tertiary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                pendingSessions.length == 1
                    ? '1 session is waiting on its photo & rating.'
                    : '${pendingSessions.length} sessions are waiting on their photo & rating.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_forward_ios),
          ],
        ),
      ),
    );
  }
}

class _ActiveSessionView extends StatelessWidget {
  const _ActiveSessionView({required this.provider});

  final SessionProvider provider;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TimerDisplay(
              phaseLabel: provider.phaseLabel,
              remaining: provider.remaining,
              subjectTag: provider.session?.subjectTag,
              totalDuration: provider.currentPhaseTotalDuration,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: Icon(
                    provider.isPaused ? Icons.play_arrow : Icons.pause,
                    size: 36,
                  ),
                  onPressed: provider.isPaused ? provider.resumeSession : provider.pauseSession,
                  color: Theme.of(context).colorScheme.primary,
                ),
                ElevatedButton.icon(
                  onPressed: () => _confirmEndEarly(context, provider),
                  icon: const Icon(Icons.stop_circle_outlined, size: 20),
                  label: const Text('End Early'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmEndEarly(BuildContext context, SessionProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End session early?'),
        content: const Text(
          "This will be logged as ended early - it still counts toward your history, "
          "but it's flagged and affects your streak. You'll still need to add a photo "
          "and rating, same as finishing normally.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep going'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('End Early'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.endSessionEarly();
    }
  }
}