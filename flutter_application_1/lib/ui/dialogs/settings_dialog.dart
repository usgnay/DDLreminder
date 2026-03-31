import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../services/autostart_service.dart';
import '../../services/font_service.dart';
import '../../services/settings_service.dart';

Future<void> showSettingsDialog(
  BuildContext context,
  SettingsService settings,
  AutostartService autostart,
  FontService fonts,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SettingsDialog(settings: settings, autostart: autostart, fonts: fonts),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.settings, required this.autostart, required this.fonts});

  final SettingsService settings;
  final AutostartService autostart;
  final FontService fonts;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  static const double _recurringReminderMin = 1;
  static const double _recurringReminderMax = 7;

  late AppSettings _working;
  late TextEditingController _sloganController;
  late TextEditingController _textColorController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _panelColorController;
  late TextEditingController _urgencyTintColorController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  late Future<List<String>> _fontsFuture;
  late final bool _fontEnumerationSupported;

  @override
  void initState() {
    super.initState();
    _working = _normalizeSettings(widget.settings.value);
    _sloganController = TextEditingController(text: _working.slogan);
    _textColorController = TextEditingController(text: _hexFromColor(_working.textColorValue));
    _backgroundColorController = TextEditingController(text: _hexFromColor(_working.backgroundColorValue));
    _panelColorController = TextEditingController(text: _hexFromColor(_working.panelColorValue));
    _urgencyTintColorController = TextEditingController(text: _hexFromColor(_working.urgencyTintColorValue));
    _fontEnumerationSupported = widget.fonts.isEnumerationSupported;
    _fontsFuture = _fontEnumerationSupported ? widget.fonts.installedFonts() : Future.value(const []);
  }

  @override
  void dispose() {
    _sloganController.dispose();
    _textColorController.dispose();
    _backgroundColorController.dispose();
    _panelColorController.dispose();
    _urgencyTintColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _working.language;
    final maxDialogHeight = MediaQuery.of(context).size.height * .65;
    final weeklyReminderValue = _clampRecurringReminder(_working.weeklyReminderDays).toDouble();
    final monthlyReminderValue = _clampRecurringReminder(_working.monthlyReminderDays).toDouble();

    return AlertDialog(
      title: Text(tr(lang, '设置', 'Settings')),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 420, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  value: _working.autoLaunch,
                  onChanged: (value) => setState(() => _working = _working.copyWith(autoLaunch: value)),
                  title: Text(tr(lang, '开机自启动', 'Launch at startup')),
                  subtitle: Text(tr(lang, '适用于桌面端安装版本', 'For desktop installations only')),
                ),
                DropdownButtonFormField<AppLanguage>(
                  initialValue: _working.language,
                  decoration: InputDecoration(labelText: tr(lang, '界面语言', 'Interface language')),
                  items: AppLanguage.values
                      .map((language) => DropdownMenuItem(value: language, child: Text(language.displayName)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _working = _working.copyWith(language: value));
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppFontFamily>(
                  initialValue: _working.fontFamily,
                  decoration: InputDecoration(labelText: tr(lang, '界面字体', 'Interface font')),
                  items: AppFontFamily.values
                      .map((font) => DropdownMenuItem(value: font, child: Text(font.displayName(lang))))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _working = _working.copyWith(
                        fontFamily: value,
                        customFontFamily: value == AppFontFamily.custom ? _working.customFontFamily : null,
                      );
                    });
                  },
                ),
                if (_working.fontFamily == AppFontFamily.custom) ...[
                  const SizedBox(height: 12),
                  if (_fontEnumerationSupported)
                    _CustomFontPicker(
                      future: _fontsFuture,
                      language: lang,
                      selected: _working.customFontFamily,
                      onChanged: (value) => setState(() => _working = _working.copyWith(customFontFamily: value?.trim())),
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tr(lang, '当前平台暂不支持列出系统字体，请手动输入', 'System fonts cannot be listed on this platform.'),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                ],
                ListTile(
                  title: Text(tr(lang, '提醒阈值 (天)', 'Reminder threshold (days)')),
                  subtitle: Slider(
                    value: _working.reminderThresholdDays.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    label: lang == AppLanguage.zh
                        ? '${_working.reminderThresholdDays} 天'
                        : '${_working.reminderThresholdDays} day(s)',
                    onChanged: (value) => setState(() => _working = _working.copyWith(reminderThresholdDays: value.round())),
                  ),
                ),
                SwitchListTile.adaptive(
                  value: _working.showRecurringPanel,
                  onChanged: (value) => setState(() => _working = _working.copyWith(showRecurringPanel: value)),
                  title: Text(tr(lang, '显示周期任务列表', 'Show recurring task list')),
                  subtitle: Text(tr(lang, '在面板中展示每周/每月循环任务', 'Display weekly/monthly tasks above the list')),
                  contentPadding: EdgeInsets.zero,
                ),
                ListTile(
                  title: Text(tr(lang, '每周任务提醒阈值 (天)', 'Weekly reminder lead time (days)')),
                  subtitle: Slider(
                    value: weeklyReminderValue,
                    min: _recurringReminderMin,
                    max: _recurringReminderMax,
                    divisions: (_recurringReminderMax - _recurringReminderMin).round(),
                    label: lang == AppLanguage.zh ? '${weeklyReminderValue.round()} 天' : '${weeklyReminderValue.round()} day(s)',
                    onChanged: _working.showRecurringPanel
                        ? (value) => setState(() => _working = _working.copyWith(weeklyReminderDays: value.round()))
                        : null,
                  ),
                ),
                ListTile(
                  title: Text(tr(lang, '每月任务提醒阈值 (天)', 'Monthly reminder lead time (days)')),
                  subtitle: Slider(
                    value: monthlyReminderValue,
                    min: _recurringReminderMin,
                    max: _recurringReminderMax,
                    divisions: (_recurringReminderMax - _recurringReminderMin).round(),
                    label: lang == AppLanguage.zh ? '${monthlyReminderValue.round()} 天' : '${monthlyReminderValue.round()} day(s)',
                    onChanged: _working.showRecurringPanel
                        ? (value) => setState(() => _working = _working.copyWith(monthlyReminderDays: value.round()))
                        : null,
                  ),
                ),
                TextField(
                  controller: _sloganController,
                  decoration: InputDecoration(labelText: tr(lang, '自定义标语', 'Custom slogan')),
                  onChanged: (value) => _working = _working.copyWith(slogan: value.trim()),
                ),
                const SizedBox(height: 12),
                _buildHexColorField(
                  label: tr(lang, '文字颜色 (HEX)', 'Text color (HEX)'),
                  controller: _textColorController,
                  onValidColor: (value) => setState(() => _working = _working.copyWith(textColorValue: value)),
                  language: lang,
                ),
                const SizedBox(height: 8),
                _buildHexColorField(
                  label: tr(lang, '背景颜色 (HEX)', 'Background color (HEX)'),
                  controller: _backgroundColorController,
                  onValidColor: (value) => setState(() => _working = _working.copyWith(backgroundColorValue: value)),
                  language: lang,
                ),
                const SizedBox(height: 8),
                _buildHexColorField(
                  label: tr(lang, '列表区域颜色 (HEX)', 'Panel color (HEX)'),
                  controller: _panelColorController,
                  onValidColor: (value) => setState(() => _working = _working.copyWith(panelColorValue: value)),
                  language: lang,
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(lang, '窗口背景透明度', 'Window surface opacity')),
                  subtitle: Slider(
                    value: _working.surfaceOpacity,
                    min: .55,
                    max: 1,
                    divisions: 9,
                    label: '${(_working.surfaceOpacity * 100).round()}%',
                    onChanged: (value) => setState(() => _working = _working.copyWith(surfaceOpacity: value)),
                  ),
                ),
                const SizedBox(height: 8),
                _buildHexColorField(
                  label: tr(lang, '临期提示颜色 (HEX)', 'Urgency tint color (HEX)'),
                  controller: _urgencyTintColorController,
                  onValidColor: (value) => setState(() => _working = _working.copyWith(urgencyTintColorValue: value)),
                  language: lang,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(lang, '临期遮罩强度', 'Urgency overlay strength')),
                  subtitle: Slider(
                    value: _working.urgencyOverlayOpacity,
                    min: .04,
                    max: .22,
                    divisions: 9,
                    label: '${(_working.urgencyOverlayOpacity * 100).round()}%',
                    onChanged: (value) => setState(() => _working = _working.copyWith(urgencyOverlayOpacity: value)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(tr(lang, '取消', 'Cancel')),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(tr(lang, '保存', 'Save')),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _saving = true);
    await widget.settings.update(_normalizeSettings(_working.copyWith(slogan: _sloganController.text.trim())));
    await widget.autostart.apply(enable: _working.autoLaunch);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  AppSettings _normalizeSettings(AppSettings settings) {
    return settings.copyWith(
      weeklyReminderDays: _clampRecurringReminder(settings.weeklyReminderDays),
      monthlyReminderDays: _clampRecurringReminder(settings.monthlyReminderDays),
      surfaceOpacity: settings.surfaceOpacity.clamp(.55, 1.0),
      urgencyOverlayOpacity: settings.urgencyOverlayOpacity.clamp(.04, .22),
    );
  }

  int _clampRecurringReminder(int value) {
    if (value < _recurringReminderMin) {
      return _recurringReminderMin.round();
    }
    if (value > _recurringReminderMax) {
      return _recurringReminderMax.round();
    }
    return value;
  }

  String _hexFromColor(int value) => value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

  Widget _buildHexColorField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<int> onValidColor,
    required AppLanguage language,
  }) {
    final currentColor = Color(_parseHex(controller.text) ?? Colors.black.value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, prefixText: '#', counterText: ''),
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]'))],
          validator: (value) => _validateHex(value, language),
          onChanged: (value) {
            final parsed = _parseHex(value);
            if (parsed != null) {
              onValidColor(parsed);
            }
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.black12),
              ),
            ),
            const SizedBox(width: 12),
            TextButton.icon(
              onPressed: () => _openColorPicker(controller, onValidColor, language),
              icon: const Icon(Icons.palette_outlined),
              label: Text(tr(language, '色盘选色', 'Palette picker')),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateHex(String? value, AppLanguage language) {
    if (_parseHex(value) == null) {
      return tr(language, '请输入 6 位 HEX 颜色，如 FFFFFF', 'Enter a 6-digit HEX color, e.g. FFFFFF');
    }
    return null;
  }

  int? _parseHex(String? input) {
    final sanitized = (input ?? '').replaceAll('#', '').trim();
    if (sanitized.length != 6) {
      return null;
    }
    final parsed = int.tryParse(sanitized, radix: 16);
    if (parsed == null) {
      return null;
    }
    return 0xFF000000 | parsed;
  }

  Future<void> _openColorPicker(
    TextEditingController controller,
    ValueChanged<int> onValidColor,
    AppLanguage language,
  ) async {
    Color temp = Color(_parseHex(controller.text) ?? Colors.black.value);
    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) {
        final size = MediaQuery.of(dialogContext).size;
        return AlertDialog(
          title: Text(tr(language, '选择颜色', 'Pick a color')),
          content: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 380, maxHeight: size.height * .62),
            child: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: temp,
                enableAlpha: false,
                portraitOnly: true,
                onColorChanged: (color) => temp = color,
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(tr(language, '取消', 'Cancel'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, temp), child: Text(tr(language, '确定', 'OK'))),
          ],
        );
      },
    );
    if (picked == null) {
      return;
    }
    final hex = _hexFromColor(picked.value);
    controller.text = hex;
    onValidColor(picked.value);
  }
}

class _CustomFontPicker extends StatelessWidget {
  const _CustomFontPicker({
    required this.future,
    required this.language,
    required this.selected,
    required this.onChanged,
  });

  final Future<List<String>> future;
  final AppLanguage language;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        if (snapshot.hasError) {
          return Text(
            tr(language, '字体列表加载失败，请稍后再试', 'Failed to load system fonts. Please retry.'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error),
          );
        }
        final fonts = snapshot.data ?? const [];
        if (fonts.isEmpty) {
          return Text(tr(language, '未检测到可用系统字体', 'No system fonts detected.'));
        }
        final items = fonts
            .map((font) => DropdownMenuItem<String>(value: font, child: Text(font, overflow: TextOverflow.ellipsis)))
            .toList(growable: true);
        if (selected != null && selected!.isNotEmpty && !fonts.contains(selected)) {
          items.insert(
            0,
            DropdownMenuItem<String>(
              value: selected,
              child: Text('${selected!} (${tr(language, '当前设备缺少', 'missing')})', overflow: TextOverflow.ellipsis),
            ),
          );
        }
        return DropdownButtonFormField<String>(
          value: selected?.isNotEmpty == true ? selected : null,
          decoration: InputDecoration(labelText: tr(language, '选择系统字体', 'Choose a system font')),
          items: items,
          isExpanded: true,
          onChanged: onChanged,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return tr(language, '请选择字体', 'Select a font');
            }
            return null;
          },
        );
      },
    );
  }
}
