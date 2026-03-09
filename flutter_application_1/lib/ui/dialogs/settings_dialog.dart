import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../services/autostart_service.dart';
import '../../services/settings_service.dart';

Future<void> showSettingsDialog(BuildContext context, SettingsService settings, AutostartService autostart) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SettingsDialog(settings: settings, autostart: autostart),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({required this.settings, required this.autostart});

  final SettingsService settings;
  final AutostartService autostart;

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late AppSettings _working;
  late TextEditingController _sloganController;
  late TextEditingController _textColorController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _panelColorController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _working = widget.settings.value;
    _sloganController = TextEditingController(text: _working.slogan);
    _textColorController = TextEditingController(text: _hexFromColor(_working.textColorValue));
    _backgroundColorController = TextEditingController(text: _hexFromColor(_working.backgroundColorValue));
    _panelColorController = TextEditingController(text: _hexFromColor(_working.panelColorValue));
  }

  @override
  void dispose() {
    _sloganController.dispose();
    _textColorController.dispose();
    _backgroundColorController.dispose();
    _panelColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _working.language;
    final maxDialogHeight = MediaQuery.of(context).size.height * .65;
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
                      .map((language) => DropdownMenuItem(
                            value: language,
                            child: Text(language.displayName),
                          ))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _working = _working.copyWith(language: value));
                  },
                ),
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
                    onChanged: (value) => setState(
                      () => _working = _working.copyWith(reminderThresholdDays: value.round()),
                    ),
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
                    value: _working.weeklyReminderDays.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label:
                        lang == AppLanguage.zh ? '${_working.weeklyReminderDays} 天' : '${_working.weeklyReminderDays} day(s)',
                    onChanged: _working.showRecurringPanel
                        ? (value) => setState(() => _working = _working.copyWith(weeklyReminderDays: value.round()))
                        : null,
                  ),
                ),
                ListTile(
                  title: Text(tr(lang, '每月任务提醒阈值 (天)', 'Monthly reminder lead time (days)')),
                  subtitle: Slider(
                    value: _working.monthlyReminderDays.toDouble(),
                    min: 1,
                    max: 3,
                    divisions: 2,
                    label:
                        lang == AppLanguage.zh ? '${_working.monthlyReminderDays} 天' : '${_working.monthlyReminderDays} day(s)',
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
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(tr(lang, '取消', 'Cancel'))),
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
    await widget.settings.update(_working.copyWith(slogan: _sloganController.text.trim()));
    await widget.autostart.apply(enable: _working.autoLaunch);
    if (mounted) {
      Navigator.pop(context);
    }
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
          decoration: InputDecoration(
            labelText: label,
            prefixText: '#',
            counterText: '',
          ),
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
      builder: (_) => AlertDialog(
        title: Text(tr(language, '选择颜色', 'Pick a color')),
        content: ColorPicker(
          pickerColor: temp,
          enableAlpha: false,
          onColorChanged: (color) => temp = color,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(tr(language, '取消', 'Cancel'))),
          FilledButton(onPressed: () => Navigator.pop(context, temp), child: Text(tr(language, '确定', 'OK'))),
        ],
      ),
    );
    if (picked == null) {
      return;
    }
    final hex = _hexFromColor(picked.value);
    controller.text = hex;
    onValidColor(picked.value);
  }
}
