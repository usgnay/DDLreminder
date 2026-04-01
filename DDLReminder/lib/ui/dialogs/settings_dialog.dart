import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../services/autostart_service.dart';
import '../../services/font_service.dart';
import '../../services/settings_service.dart';
import '../../services/update_service.dart';

Future<void> showSettingsDialog(
  BuildContext context,
  SettingsService settings,
  AutostartService autostart,
  FontService fonts,
  UpdateService updates,
) {
  return showDialog<void>(
    context: context,
    builder: (_) => _SettingsDialog(settings: settings, autostart: autostart, fonts: fonts, updates: updates),
  );
}

class _SettingsDialog extends StatefulWidget {
  const _SettingsDialog({
    required this.settings,
    required this.autostart,
    required this.fonts,
    required this.updates,
  });

  final SettingsService settings;
  final AutostartService autostart;
  final FontService fonts;
  final UpdateService updates;

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
  late TextEditingController _backgroundOverlayColorController;
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _checkingUpdate = false;
  late Future<List<String>> _fontsFuture;
  late Future<String> _versionFuture;
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
    _backgroundOverlayColorController = TextEditingController(text: _hexFromColor(_working.backgroundImageOverlayColorValue));
    _fontEnumerationSupported = widget.fonts.isEnumerationSupported;
    _fontsFuture = _fontEnumerationSupported ? widget.fonts.installedFonts() : Future.value(const []);
    _versionFuture = widget.updates.currentVersion();
  }

  @override
  void dispose() {
    _sloganController.dispose();
    _textColorController.dispose();
    _backgroundColorController.dispose();
    _panelColorController.dispose();
    _urgencyTintColorController.dispose();
    _backgroundOverlayColorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = _working.language;
    final maxDialogHeight = MediaQuery.of(context).size.height * .72;
    final weeklyReminderValue = _clampRecurringReminder(_working.weeklyReminderDays).toDouble();
    final monthlyReminderValue = _clampRecurringReminder(_working.monthlyReminderDays).toDouble();

    return AlertDialog(
      title: Text(tr(lang, '设置', 'Settings')),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 440, maxHeight: maxDialogHeight),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FutureBuilder<String>(
                  future: _versionFuture,
                  builder: (context, snapshot) {
                    final version = snapshot.data ?? '--';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(tr(lang, '当前版本', 'Current version')),
                      subtitle: Text(version),
                      trailing: FilledButton.tonal(
                        onPressed: _checkingUpdate ? null : () => _checkForUpdates(lang),
                        child: _checkingUpdate
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(tr(lang, '检查更新', 'Check updates')),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: _working.autoLaunch,
                  onChanged: (value) => setState(() => _working = _working.copyWith(autoLaunch: value)),
                  title: Text(tr(lang, '开机自启动', 'Launch at startup')),
                  subtitle: Text(tr(lang, '适用于桌面安装版本', 'For desktop installations only')),
                ),
                SwitchListTile(
                  value: _working.showCloseConfirmDialog,
                  onChanged: (value) => setState(() => _working = _working.copyWith(showCloseConfirmDialog: value)),
                  title: Text(tr(lang, '关闭时显示确认窗口', 'Show close confirmation')),
                  subtitle: Text(
                    tr(
                      lang,
                      '点击右上角关闭按钮时，先询问是最小化到托盘还是直接退出',
                      'Ask whether to minimize to tray or exit when closing the window',
                    ),
                  ),
                ),
                DropdownButtonFormField<CloseAction>(
                  initialValue: _working.closeAction,
                  decoration: InputDecoration(labelText: tr(lang, '默认关闭行为', 'Default close action')),
                  items: CloseAction.values
                      .map(
                        (action) => DropdownMenuItem(
                          value: action,
                          child: Text(_closeActionLabel(action, lang)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _working = _working.copyWith(closeAction: value));
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<AppLanguage>(
                  initialValue: _working.language,
                  decoration: InputDecoration(labelText: tr(lang, '界面语言', 'Interface language')),
                  items: AppLanguage.values
                      .map((language) => DropdownMenuItem(value: language, child: Text(language.displayName)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _working = _working.copyWith(language: value));
                    }
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
                    if (value != null) {
                      setState(() {
                        _working = _working.copyWith(
                          fontFamily: value,
                          customFontFamily: value == AppFontFamily.custom ? _working.customFontFamily : null,
                        );
                      });
                    }
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
                  title: Text(tr(lang, '提醒阈值（天）', 'Reminder threshold (days)')),
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
                  title: Text(tr(lang, '每周任务提醒阈值（天）', 'Weekly reminder lead time (days)')),
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
                  title: Text(tr(lang, '每月任务提醒阈值（天）', 'Monthly reminder lead time (days)')),
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
                  decoration: InputDecoration(labelText: tr(lang, '自定义标题', 'Custom slogan')),
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
                _buildBackgroundModeSection(lang),
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
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(lang, '标题栏显示宽度', 'Header title width')),
                  subtitle: Slider(
                    value: _working.headerTitleMaxWidth,
                    min: 140,
                    max: 320,
                    divisions: 9,
                    label: '${_working.headerTitleMaxWidth.round()} px',
                    onChanged: (value) => setState(() => _working = _working.copyWith(headerTitleMaxWidth: value)),
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

  Widget _buildBackgroundModeSection(AppLanguage language) {
    final usingImage = _working.backgroundMode == BackgroundMode.image;
    final imagePath = _working.backgroundImagePath?.trim();
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<BackgroundMode>(
          initialValue: _working.backgroundMode,
          decoration: InputDecoration(labelText: tr(language, '背景模式', 'Background mode')),
          items: [
            DropdownMenuItem(
              value: BackgroundMode.color,
              child: Text(tr(language, '纯色背景', 'Solid color')),
            ),
            DropdownMenuItem(
              value: BackgroundMode.image,
              child: Text(tr(language, '图片背景', 'Image background')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _working = _working.copyWith(backgroundMode: value));
            }
          },
        ),
        const SizedBox(height: 8),
        if (!usingImage)
          _buildHexColorField(
            label: tr(language, '背景颜色 (HEX)', 'Background color (HEX)'),
            controller: _backgroundColorController,
            onValidColor: (value) => setState(() => _working = _working.copyWith(backgroundColorValue: value)),
            language: language,
          ),
        if (usingImage) ...[
          Text(tr(language, '背景图片', 'Background image')),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  hasImage ? imagePath : tr(language, '未选择图片', 'No image selected'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: _pickBackgroundImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(tr(language, '选择', 'Choose')),
              ),
              if (hasImage)
                TextButton(
                  onPressed: () => setState(() => _working = _working.copyWith(backgroundImagePath: null)),
                  child: Text(tr(language, '清除', 'Clear')),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BackgroundImageFit>(
            initialValue: _working.backgroundImageFit,
            decoration: InputDecoration(labelText: tr(language, '图片适配', 'Image fit')),
            items: [
              DropdownMenuItem(
                value: BackgroundImageFit.cover,
                child: Text(tr(language, '铺满裁切', 'Cover')),
              ),
              DropdownMenuItem(
                value: BackgroundImageFit.contain,
                child: Text(tr(language, '完整显示', 'Contain')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _working = _working.copyWith(backgroundImageFit: value));
              }
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<BackgroundImageAnchor>(
            initialValue: _working.backgroundImageAnchor,
            decoration: InputDecoration(labelText: tr(language, '焦点预设', 'Focus preset')),
            items: [
              DropdownMenuItem(value: BackgroundImageAnchor.center, child: Text(tr(language, '居中', 'Center'))),
              DropdownMenuItem(value: BackgroundImageAnchor.top, child: Text(tr(language, '顶部', 'Top'))),
              DropdownMenuItem(value: BackgroundImageAnchor.bottom, child: Text(tr(language, '底部', 'Bottom'))),
              DropdownMenuItem(value: BackgroundImageAnchor.left, child: Text(tr(language, '左侧', 'Left'))),
              DropdownMenuItem(value: BackgroundImageAnchor.right, child: Text(tr(language, '右侧', 'Right'))),
              DropdownMenuItem(value: BackgroundImageAnchor.topLeft, child: Text(tr(language, '左上', 'Top left'))),
              DropdownMenuItem(value: BackgroundImageAnchor.topRight, child: Text(tr(language, '右上', 'Top right'))),
              DropdownMenuItem(value: BackgroundImageAnchor.bottomLeft, child: Text(tr(language, '左下', 'Bottom left'))),
              DropdownMenuItem(value: BackgroundImageAnchor.bottomRight, child: Text(tr(language, '右下', 'Bottom right'))),
            ],
            onChanged: (value) {
              if (value == null) {
                return;
              }
              final alignment = value.alignment;
              setState(() {
                _working = _working.copyWith(
                  backgroundImageAnchor: value,
                  backgroundImageFocusX: alignment.x,
                  backgroundImageFocusY: alignment.y,
                );
              });
            },
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            _buildBackgroundFocusPreview(language, imagePath),
          ],
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(language, '背景图透明度', 'Background image opacity')),
            subtitle: Slider(
              value: _working.backgroundImageOpacity,
              min: .05,
              max: 1,
              divisions: 19,
              label: '${(_working.backgroundImageOpacity * 100).round()}%',
              onChanged: hasImage
                  ? (value) => setState(() => _working = _working.copyWith(backgroundImageOpacity: value))
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          _buildHexColorField(
            label: tr(language, '背景图蒙版颜色 (HEX)', 'Background overlay color (HEX)'),
            controller: _backgroundOverlayColorController,
            onValidColor: (value) => setState(() => _working = _working.copyWith(backgroundImageOverlayColorValue: value)),
            language: language,
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(language, '背景图蒙版强度', 'Background overlay strength')),
            subtitle: Slider(
              value: _working.backgroundImageOverlayOpacity,
              min: .0,
              max: .45,
              divisions: 9,
              label: '${(_working.backgroundImageOverlayOpacity * 100).round()}%',
              onChanged: hasImage
                  ? (value) => setState(() => _working = _working.copyWith(backgroundImageOverlayOpacity: value))
                  : null,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBackgroundFocusPreview(AppLanguage language, String imagePath) {
    final imageFile = File(imagePath);
    const previewWidth = 320.0;
    const previewHeight = 140.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(language, '拖动预览设置焦点', 'Drag preview to set focus')),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onPanDown: (details) => _updateBackgroundFocus(details.localPosition, previewWidth, previewHeight),
            onPanUpdate: (details) => _updateBackgroundFocus(details.localPosition, previewWidth, previewHeight),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: Image.file(
                      imageFile,
                      fit: _working.backgroundImageFit == BackgroundImageFit.cover ? BoxFit.cover : BoxFit.contain,
                      alignment: Alignment(_working.backgroundImageFocusX, _working.backgroundImageFocusY),
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: Text(tr(language, '预览不可用', 'Preview unavailable')),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white.withOpacity(.55)),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: ((_working.backgroundImageFocusX + 1) / 2) * previewWidth - 9,
                    top: ((_working.backgroundImageFocusY + 1) / 2) * previewHeight - 9,
                    child: IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black.withOpacity(.28)),
                          boxShadow: const [
                            BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateBackgroundFocus(Offset localPosition, double width, double height) {
    final nextX = ((localPosition.dx / width) * 2 - 1).clamp(-1.0, 1.0);
    final nextY = ((localPosition.dy / height) * 2 - 1).clamp(-1.0, 1.0);
    setState(() {
      _working = _working.copyWith(
        backgroundImageAnchor: BackgroundImageAnchor.center,
        backgroundImageFocusX: nextX,
        backgroundImageFocusY: nextY,
      );
    });
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

  Future<void> _checkForUpdates(AppLanguage language) async {
    setState(() => _checkingUpdate = true);
    final result = await widget.updates.checkForUpdate();
    if (!mounted) {
      return;
    }
    setState(() => _checkingUpdate = false);

    if (result.release == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr(language, '更新检查失败', 'Update check failed')),
          content: Text(result.message ?? tr(language, '未获取到发布信息', 'Release information was unavailable.')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(language, '确定', 'OK')),
            ),
          ],
        ),
      );
      return;
    }

    if (!result.hasUpdate) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr(language, '已经是最新版本', 'Already up to date')),
          content: Text(
            tr(
              language,
              '当前版本 ${result.currentVersion} 已经是最新版本。',
              'Current version ${result.currentVersion} is already the latest.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr(language, '确定', 'OK')),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(tr(language, '发现新版本', 'Update available')),
        content: Text(
          tr(
            language,
            '当前版本 ${result.currentVersion}，最新版本 ${result.release!.version}。\n确认后将退出应用并开始更新。',
            'Current version ${result.currentVersion}, latest version ${result.release!.version}.\nThe app will exit and start updating after confirmation.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(tr(language, '取消', 'Cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(tr(language, '立即更新', 'Update now')),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    await widget.updates.startUpdate(result.release!);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  AppSettings _normalizeSettings(AppSettings settings) {
    return settings.copyWith(
      weeklyReminderDays: _clampRecurringReminder(settings.weeklyReminderDays),
      monthlyReminderDays: _clampRecurringReminder(settings.monthlyReminderDays),
      surfaceOpacity: settings.surfaceOpacity.clamp(.55, 1.0),
      backgroundImageFocusX: settings.backgroundImageFocusX.clamp(-1.0, 1.0),
      backgroundImageFocusY: settings.backgroundImageFocusY.clamp(-1.0, 1.0),
      backgroundImageOpacity: settings.backgroundImageOpacity.clamp(.05, 1.0),
      backgroundImageOverlayOpacity: settings.backgroundImageOverlayOpacity.clamp(.0, .45),
      backgroundImagePath: settings.backgroundImagePath?.trim().isEmpty == true ? null : settings.backgroundImagePath?.trim(),
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

  String _closeActionLabel(CloseAction action, AppLanguage language) {
    switch (action) {
      case CloseAction.minimizeToTray:
        return tr(language, '最小化到托盘', 'Minimize to tray');
      case CloseAction.exitApp:
        return tr(language, '直接退出', 'Exit directly');
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

  Future<void> _pickBackgroundImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp', 'bmp'],
    );
    final path = result?.files.single.path?.trim();
    if (path == null || path.isEmpty) {
      return;
    }
    final cachedPath = await widget.settings.cacheBackgroundImage(path);
    setState(() {
      _working = _working.copyWith(
        backgroundMode: BackgroundMode.image,
        backgroundImagePath: cachedPath,
      );
    });
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(tr(language, '取消', 'Cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, temp),
              child: Text(tr(language, '确定', 'OK')),
            ),
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
            tr(language, '字体列表加载失败，请稍后重试', 'Failed to load system fonts. Please retry.'),
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
          initialValue: selected?.isNotEmpty == true ? selected : null,
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
