import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/i18n.dart';
import '../../models/app_settings.dart';
import '../../services/settings_service.dart';

class MobileSettingsPage extends StatefulWidget {
  const MobileSettingsPage({
    super.key,
    required this.settings,
    required this.onPreviewDate,
    required this.onImportTasks,
  });

  final SettingsService settings;
  final Future<void> Function() onPreviewDate;
  final Future<void> Function() onImportTasks;

  @override
  State<MobileSettingsPage> createState() => _MobileSettingsPageState();
}

class _MobileSettingsPageState extends State<MobileSettingsPage> {
  late AppSettings _working;
  late TextEditingController _sloganController;
  late TextEditingController _backgroundColorController;
  late TextEditingController _panelColorController;
  late TextEditingController _appBarColorController;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _working = widget.settings.value;
    _sloganController = TextEditingController(text: _working.slogan);
    _backgroundColorController = TextEditingController(
      text: _hexFromColor(_working.backgroundColorValue),
    );
    _panelColorController = TextEditingController(
      text: _hexFromColor(_working.panelColorValue),
    );
    _appBarColorController = TextEditingController(
      text: _hexFromColor(_working.mobileAppBarColorValue),
    );
    _loadVersion();
  }

  @override
  void dispose() {
    _sloganController.dispose();
    _backgroundColorController.dispose();
    _panelColorController.dispose();
    _appBarColorController.dispose();
    super.dispose();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    final build = info.buildNumber.trim();
    final version = info.version.trim();
    if (!mounted) {
      return;
    }
    setState(() {
      _versionLabel = build.isEmpty || version.contains('+')
          ? version
          : '$version+$build';
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = _working.language;
    return Scaffold(
      appBar: AppBar(title: Text(tr(language, '手机端设置', 'Mobile settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_versionLabel != null)
            _SectionCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(tr(language, '当前版本', 'Current version')),
                subtitle: Text(_versionLabel!),
              ),
            ),
          _SectionCard(
            title: tr(language, '基础设置', 'General'),
            child: Column(
              children: [
                DropdownButtonFormField<AppLanguage>(
                  initialValue: _working.language,
                  decoration: InputDecoration(
                    labelText: tr(language, '界面语言', 'Language'),
                  ),
                  items: AppLanguage.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.displayName),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      _update(_working.copyWith(language: value));
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<AppFontFamily>(
                  initialValue: _working.fontFamily,
                  decoration: InputDecoration(
                    labelText: tr(language, '界面字体', 'Font'),
                  ),
                  items:
                      const [
                            AppFontFamily.system,
                            AppFontFamily.notoSans,
                            AppFontFamily.inter,
                          ]
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item.displayName(language)),
                            ),
                          )
                          .toList(growable: false),
                  onChanged: (value) {
                    if (value != null) {
                      _update(
                        _working.copyWith(
                          fontFamily: value,
                          customFontFamily: null,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _working.showRecurringPanel,
                  title: Text(
                    tr(language, '显示周期任务区块', 'Show recurring section'),
                  ),
                  onChanged: (value) =>
                      _update(_working.copyWith(showRecurringPanel: value)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sloganController,
                  decoration: InputDecoration(
                    labelText: tr(language, '应用标语', 'Slogan'),
                    hintText: tr(
                      language,
                      '例如：专注每一件重要的事',
                      'For example: Stay on top of what matters',
                    ),
                  ),
                  onChanged: (value) =>
                      _update(_working.copyWith(slogan: value.trim())),
                ),
              ],
            ),
          ),
          _buildBackgroundSection(language),
          _buildReminderSection(language),
          _SectionCard(
            title: tr(language, '任务工具', 'Task tools'),
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_note_outlined),
                  title: Text(
                    tr(language, '查看指定日期的截止情况', 'Preview a specific date'),
                  ),
                  subtitle: Text(
                    tr(
                      language,
                      '查看当日视角下每项任务的截止状态。',
                      'Review each task as if the selected date were today.',
                    ),
                  ),
                  onTap: widget.onPreviewDate,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.file_upload_outlined),
                  title: Text(tr(language, '导入任务', 'Import tasks')),
                  subtitle: Text(
                    tr(
                      language,
                      '从 JSON 文件导入任务数据。',
                      'Import task data from a JSON file.',
                    ),
                  ),
                  onTap: widget.onImportTasks,
                ),
              ],
            ),
          ),
          _SectionCard(
            title: tr(language, '使用说明', 'Notes'),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.phone_android_outlined),
              title: Text(
                tr(
                  language,
                  '移动端已支持任务管理、前台提醒与桌面小部件。',
                  'Mobile now supports task management, foreground reminders, and a home-screen widget.',
                ),
              ),
              subtitle: Text(
                tr(
                  language,
                  '桌面端的开机自启、托盘与自更新功能仍保留在桌面版中。',
                  'Desktop-only auto-start, tray behavior, and self-update remain in desktop builds.',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundSection(AppLanguage language) {
    final usingImage = _working.backgroundMode == BackgroundMode.image;
    final imagePath = _working.backgroundImagePath?.trim();
    final hasImage = imagePath != null && imagePath.isNotEmpty;

    return _SectionCard(
      title: tr(language, '背景与外观', 'Background and chrome'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<BackgroundMode>(
            initialValue: _working.backgroundMode,
            decoration: InputDecoration(
              labelText: tr(language, '背景模式', 'Background mode'),
            ),
            items: [
              DropdownMenuItem(
                value: BackgroundMode.color,
                child: Text(tr(language, '纯色背景', 'Solid color')),
              ),
              DropdownMenuItem(
                value: BackgroundMode.image,
                child: Text(tr(language, '自定义图片', 'Custom image')),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _update(_working.copyWith(backgroundMode: value));
              }
            },
          ),
          const SizedBox(height: 12),
          if (!usingImage) ...[
            _buildHexColorField(
              label: tr(language, '背景颜色 (HEX)', 'Background color (HEX)'),
              controller: _backgroundColorController,
              onValidColor: (value) =>
                  _update(_working.copyWith(backgroundColorValue: value)),
              language: language,
            ),
            const SizedBox(height: 12),
            _buildHexColorField(
              label: tr(language, '顶部栏颜色 (HEX)', 'App bar color (HEX)'),
              controller: _appBarColorController,
              onValidColor: (value) =>
                  _update(_working.copyWith(mobileAppBarColorValue: value)),
              language: language,
            ),
          ],
          if (usingImage) ...[
            Text(tr(language, '背景图片', 'Background image')),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    hasImage
                        ? imagePath
                        : tr(language, '未选择图片', 'No image selected'),
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
                    onPressed: () =>
                        _update(_working.copyWith(backgroundImagePath: null)),
                    child: Text(tr(language, '清除', 'Clear')),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BackgroundImageFit>(
              initialValue: _working.backgroundImageFit,
              decoration: InputDecoration(
                labelText: tr(language, '图片适配', 'Image fit'),
              ),
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
                  _update(_working.copyWith(backgroundImageFit: value));
                }
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<BackgroundImageAnchor>(
              initialValue: _working.backgroundImageAnchor,
              decoration: InputDecoration(
                labelText: tr(language, '焦点预设', 'Focus preset'),
              ),
              items: [
                DropdownMenuItem(
                  value: BackgroundImageAnchor.center,
                  child: Text(tr(language, '居中', 'Center')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.top,
                  child: Text(tr(language, '顶部', 'Top')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.bottom,
                  child: Text(tr(language, '底部', 'Bottom')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.left,
                  child: Text(tr(language, '左侧', 'Left')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.right,
                  child: Text(tr(language, '右侧', 'Right')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.topLeft,
                  child: Text(tr(language, '左上', 'Top left')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.topRight,
                  child: Text(tr(language, '右上', 'Top right')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.bottomLeft,
                  child: Text(tr(language, '左下', 'Bottom left')),
                ),
                DropdownMenuItem(
                  value: BackgroundImageAnchor.bottomRight,
                  child: Text(tr(language, '右下', 'Bottom right')),
                ),
              ],
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                final alignment = value.alignment;
                _update(
                  _working.copyWith(
                    backgroundImageAnchor: value,
                    backgroundImageFocusX: alignment.x,
                    backgroundImageFocusY: alignment.y,
                  ),
                );
              },
            ),
            if (hasImage) ...[
              const SizedBox(height: 8),
              _buildBackgroundFocusPreview(language, imagePath),
            ],
          ],
          const SizedBox(height: 12),
          _buildHexColorField(
            label: tr(language, '任务卡片颜色 (HEX)', 'Task card color (HEX)'),
            controller: _panelColorController,
            onValidColor: (value) =>
                _update(_working.copyWith(panelColorValue: value)),
            language: language,
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _working.mobileFollowSystemOverlay,
            title: Text(
              tr(
                language,
                '跟随系统深浅色模式添加遮罩',
                'Follow system light/dark mode with overlay',
              ),
            ),
            subtitle: Text(
              tr(
                language,
                '浅色模式添加白色柔光，深色模式添加黑色半透明遮罩。',
                'Add a white veil in light mode and a dark veil in dark mode.',
              ),
            ),
            onChanged: (value) =>
                _update(_working.copyWith(mobileFollowSystemOverlay: value)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(tr(language, '遮罩强度', 'Overlay strength')),
            subtitle: Slider(
              value: _working.mobileSystemOverlayOpacity,
              min: .0,
              max: .45,
              divisions: 9,
              label: '${(_working.mobileSystemOverlayOpacity * 100).round()}%',
              onChanged: _working.mobileFollowSystemOverlay
                  ? (value) => _update(
                      _working.copyWith(mobileSystemOverlayOpacity: value),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection(AppLanguage language) {
    return _SectionCard(
      title: tr(language, '进入应用提醒', 'App-entry reminders'),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _working.mobileEntryReminderEnabled,
            title: Text(tr(language, '进入应用时提醒快到期任务', 'Remind on app entry')),
            subtitle: Text(
              tr(
                language,
                '每次回到应用前台时检查任务，并在达到提醒条件后弹出提示。',
                'Check tasks whenever the app returns to the foreground and show a reminder when conditions are met.',
              ),
            ),
            onChanged: (value) =>
                _update(_working.copyWith(mobileEntryReminderEnabled: value)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              tr(language, '具体时间任务提前提醒小时数', 'Lead hours before timed tasks'),
            ),
            subtitle: Slider(
              value: _working.mobileReminderLeadHours.toDouble(),
              min: 1,
              max: 12,
              divisions: 11,
              label: '${_working.mobileReminderLeadHours}h',
              onChanged: _working.mobileEntryReminderEnabled
                  ? (value) => _update(
                      _working.copyWith(mobileReminderLeadHours: value.round()),
                    )
                  : null,
            ),
          ),
          _HintText(
            text: tr(
              language,
              '带具体时间的任务会在截止前若干小时开始提醒；无具体时间和周期任务会在到期当天进入应用时提醒。',
              'Timed tasks start reminding a few hours before due time; date-only and recurring tasks remind when you open the app on the due day.',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundFocusPreview(AppLanguage language, String imagePath) {
    final imageFile = File(imagePath);
    const previewWidth = 320.0;
    const previewHeight = 150.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr(language, '拖动预览设置焦点', 'Drag preview to set focus')),
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onPanDown: (details) => _updateBackgroundFocus(
              details.localPosition,
              previewWidth,
              previewHeight,
            ),
            onPanUpdate: (details) => _updateBackgroundFocus(
              details.localPosition,
              previewWidth,
              previewHeight,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Stack(
                children: [
                  SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: Image.file(
                      imageFile,
                      fit:
                          _working.backgroundImageFit ==
                              BackgroundImageFit.cover
                          ? BoxFit.cover
                          : BoxFit.contain,
                      alignment: Alignment(
                        _working.backgroundImageFocusX,
                        _working.backgroundImageFocusY,
                      ),
                      errorBuilder: (context, error, stackTrace) => ColoredBox(
                        color: Colors.black12,
                        child: Center(
                          child: Text(
                            tr(language, '预览不可用', 'Preview unavailable'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.white70),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left:
                        ((_working.backgroundImageFocusX + 1) / 2) *
                            previewWidth -
                        9,
                    top:
                        ((_working.backgroundImageFocusY + 1) / 2) *
                            previewHeight -
                        9,
                    child: IgnorePointer(
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black26),
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

  void _updateBackgroundFocus(
    Offset localPosition,
    double width,
    double height,
  ) {
    final nextX = ((localPosition.dx / width) * 2 - 1).clamp(-1.0, 1.0);
    final nextY = ((localPosition.dy / height) * 2 - 1).clamp(-1.0, 1.0);
    _update(
      _working.copyWith(
        backgroundImageAnchor: BackgroundImageAnchor.center,
        backgroundImageFocusX: nextX,
        backgroundImageFocusY: nextY,
      ),
    );
  }

  Widget _buildHexColorField({
    required String label,
    required TextEditingController controller,
    required ValueChanged<int> onValidColor,
    required AppLanguage language,
  }) {
    final currentColor = Color(
      _parseHex(controller.text) ?? Colors.black.value,
    );
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
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F]')),
          ],
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
              onPressed: () =>
                  _openColorPicker(controller, onValidColor, language),
              icon: const Icon(Icons.palette_outlined),
              label: Text(tr(language, '调色盘选色', 'Palette picker')),
            ),
          ],
        ),
      ],
    );
  }

  String? _validateHex(String? value, AppLanguage language) {
    if (_parseHex(value) == null) {
      return tr(
        language,
        '请输入 6 位 HEX 颜色，如 FFFFFF',
        'Enter a 6-digit HEX color, e.g. FFFFFF',
      );
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

  String _hexFromColor(int value) =>
      value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();

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
    _update(
      _working.copyWith(
        backgroundMode: BackgroundMode.image,
        backgroundImagePath: cachedPath,
      ),
    );
  }

  Future<void> _openColorPicker(
    TextEditingController controller,
    ValueChanged<int> onValidColor,
    AppLanguage language,
  ) async {
    Color temp = Color(_parseHex(controller.text) ?? Colors.black.value);
    final picked = await showDialog<Color>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(language, '选择颜色', 'Pick a color')),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: temp,
            enableAlpha: false,
            portraitOnly: true,
            onColorChanged: (color) => temp = color,
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
      ),
    );
    if (picked == null) {
      return;
    }
    final hex = _hexFromColor(picked.value);
    controller.text = hex;
    onValidColor(picked.value);
  }

  Future<void> _update(AppSettings next) async {
    setState(() => _working = next);
    await widget.settings.update(next);
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({this.title, required this.child});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _HintText extends StatelessWidget {
  const _HintText({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
      ),
    );
  }
}
