import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

// ══════════════════════════════════════════
// AppSettings — used by all screens
// ══════════════════════════════════════════
class AppSettings {
  static SharedPreferences? _prefs;
  static Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static Future<bool>   getAutoPlayNext()     async => (await _p).getBool('auto_play_next')    ?? true;
  static Future<void>   setAutoPlayNext(bool v)     async => (await _p).setBool('auto_play_next', v);

  static Future<bool>   getRememberPosition() async => (await _p).getBool('remember_position') ?? true;
  static Future<void>   setRememberPosition(bool v) async => (await _p).setBool('remember_position', v);

  static Future<bool>   getShowSubtitles()    async => (await _p).getBool('show_subtitles')    ?? true;
  static Future<void>   setShowSubtitles(bool v)    async => (await _p).setBool('show_subtitles', v);

  static Future<bool>   getDarkMode()         async => (await _p).getBool('dark_mode')         ?? true;
  static Future<void>   setDarkMode(bool v)         async => (await _p).setBool('dark_mode', v);

  static Future<double> getDefaultSpeed()     async => (await _p).getDouble('default_speed')   ?? 1.0;
  static Future<void>   setDefaultSpeed(double v)   async => (await _p).setDouble('default_speed', v);

  static Future<bool>   getEqEnabled()        async => (await _p).getBool('eq_enabled')        ?? false;
  static Future<void>   setEqEnabled(bool v)        async => (await _p).setBool('eq_enabled', v);

  static Future<double> getEqBass()           async => (await _p).getDouble('eq_bass')         ?? 0.0;
  static Future<void>   setEqBass(double v)         async => (await _p).setDouble('eq_bass', v);

  static Future<double> getEqMid()            async => (await _p).getDouble('eq_mid')          ?? 0.0;
  static Future<void>   setEqMid(double v)          async => (await _p).setDouble('eq_mid', v);

  static Future<double> getEqTreble()         async => (await _p).getDouble('eq_treble')       ?? 0.0;
  static Future<void>   setEqTreble(double v)       async => (await _p).setDouble('eq_treble', v);

  static Future<void> savePosition(String path, int ms) async =>
      (await _p).setInt('pos_${path.hashCode}', ms);

  static Future<int?> getSavedPosition(String path) async =>
      (await _p).getInt('pos_${path.hashCode}');
}

// ══════════════════════════════════════════
// Settings Screen
// ══════════════════════════════════════════
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoPlayNext    = true;
  bool _rememberPos     = true;
  bool _showSubs        = true;
  bool _darkMode        = true;
  double _speed         = 1.0;
  bool _eqEnabled       = false;
  double _bass          = 0.0;
  double _mid           = 0.0;
  double _treble        = 0.0;
  bool _loaded          = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _autoPlayNext = await AppSettings.getAutoPlayNext();
    _rememberPos  = await AppSettings.getRememberPosition();
    _showSubs     = await AppSettings.getShowSubtitles();
    _darkMode     = await AppSettings.getDarkMode();
    _speed        = await AppSettings.getDefaultSpeed();
    _eqEnabled    = await AppSettings.getEqEnabled();
    _bass         = await AppSettings.getEqBass();
    _mid          = await AppSettings.getEqMid();
    _treble       = await AppSettings.getEqTreble();
    if (mounted) setState(() => _loaded = true);
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.surfaceBg,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppTheme.darkBg,
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryOrange)),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF111111),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [

          // ── VIDEO ──
          _header('VIDEO'),
          _toggle(Icons.skip_next_rounded, 'Auto-play next',
            _autoPlayNext ? '✓ চালু — পরের video আপনাআপনি চলবে' : '✗ বন্ধ',
            _autoPlayNext, (v) async {
              await AppSettings.setAutoPlayNext(v);
              setState(() => _autoPlayNext = v);
              _snack('Auto-play next ${v ? "চালু" : "বন্ধ"} হয়েছে');
            }),
          _toggle(Icons.history_rounded, 'Remember position',
            _rememberPos ? '✓ চালু — যেখানে ছিলেন সেখান থেকে চলবে' : '✗ বন্ধ',
            _rememberPos, (v) async {
              await AppSettings.setRememberPosition(v);
              setState(() => _rememberPos = v);
              _snack('Remember position ${v ? "চালু" : "বন্ধ"} হয়েছে');
            }),
          _toggle(Icons.subtitles_rounded, 'Show subtitles',
            _showSubs ? '✓ চালু — SRT file থাকলে দেখাবে' : '✗ বন্ধ',
            _showSubs, (v) async {
              await AppSettings.setShowSubtitles(v);
              setState(() => _showSubs = v);
              _snack('Subtitles ${v ? "চালু" : "বন্ধ"} হয়েছে');
            }),

          // Speed
          _card(Row(
            children: [
              _icon(Icons.speed_rounded),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Default speed', style: TextStyle(color: Colors.white, fontSize: 15)),
                Text('বর্তমানে: ${_speed}x',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ])),
              Wrap(spacing: 6, children: [0.5, 1.0, 1.5, 2.0].map((s) {
                final sel = _speed == s;
                return GestureDetector(
                  onTap: () async {
                    await AppSettings.setDefaultSpeed(s);
                    setState(() => _speed = s);
                    _snack('Speed ${s}x সেট হয়েছে');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primaryOrange : AppTheme.surfaceBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('${s}x', style: TextStyle(
                      color: sel ? Colors.white : AppTheme.textSecondary,
                      fontSize: 12, fontWeight: sel ? FontWeight.w700 : FontWeight.normal,
                    )),
                  ),
                );
              }).toList()),
            ],
          )),

          // ── EQUALIZER ──
          _header('AUDIO & EQUALIZER'),
          _toggle(Icons.equalizer_rounded, 'Equalizer',
            _eqEnabled ? '✓ চালু আছে' : '✗ বন্ধ আছে',
            _eqEnabled, (v) async {
              await AppSettings.setEqEnabled(v);
              setState(() => _eqEnabled = v);
              _snack('Equalizer ${v ? "চালু" : "বন্ধ"} হয়েছে');
            }),
          if (_eqEnabled) ...[
            _eqBand('Bass (নিচু সুর)', _bass, (v) async {
              await AppSettings.setEqBass(v);
              setState(() => _bass = v);
            }),
            _eqBand('Mid (মধ্যম সুর)', _mid, (v) async {
              await AppSettings.setEqMid(v);
              setState(() => _mid = v);
            }),
            _eqBand('Treble (উচ্চ সুর)', _treble, (v) async {
              await AppSettings.setEqTreble(v);
              setState(() => _treble = v);
            }),
          ],

          // ── APPEARANCE ──
          _header('APPEARANCE'),
          _toggle(Icons.dark_mode_rounded, 'Dark mode',
            _darkMode ? '✓ চালু — Dark theme' : '✗ বন্ধ',
            _darkMode, (v) async {
              await AppSettings.setDarkMode(v);
              setState(() => _darkMode = v);
              _snack('Dark mode ${v ? "চালু" : "বন্ধ"} হয়েছে');
            }),

          // ── ABOUT ──
          _header('ABOUT'),
          _card(Row(children: [
            _icon(Icons.info_outline_rounded),
            const SizedBox(width: 14),
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('MX Media Player', style: TextStyle(color: Colors.white, fontSize: 15)),
              Text('Version 1.0.0', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ])),
        ],
      ),
    );
  }

  Widget _header(String t) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(t, style: const TextStyle(
      color: AppTheme.primaryOrange, fontSize: 12,
      fontWeight: FontWeight.w700, letterSpacing: 1.5)),
  );

  Widget _icon(IconData ic) => Container(
    width: 40, height: 40,
    decoration: BoxDecoration(color: AppTheme.surfaceBg, shape: BoxShape.circle),
    child: Icon(ic, color: AppTheme.primaryOrange, size: 20),
  );

  Widget _card(Widget child) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
    child: child,
  );

  Widget _toggle(IconData ic, String title, String sub, bool val, ValueChanged<bool> onChange) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: AppTheme.cardBg, borderRadius: BorderRadius.circular(10)),
      child: SwitchListTile(
        secondary: _icon(ic),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
        subtitle: Text(sub, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        value: val,
        onChanged: onChange,
        activeColor: AppTheme.primaryOrange,
      ),
    );

  Widget _eqBand(String label, double val, ValueChanged<double> onChange) =>
    _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
        Text('${val > 0 ? "+" : ""}${val.toStringAsFixed(1)} dB',
          style: const TextStyle(color: AppTheme.primaryOrange, fontSize: 12,
            fontWeight: FontWeight.w700)),
      ]),
      Slider(min: -10, max: 10, divisions: 40, value: val,
        activeColor: AppTheme.primaryOrange,
        inactiveColor: Colors.white12,
        onChanged: onChange),
    ]));
}
