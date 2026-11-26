import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Avvisi del timer di recupero: allarme sonoro, vibrazione e schermo acceso.
/// Tutto ciò che usa il telefono sta qui, così nei test, dove audio e schermo non esistono, si sostituisce
class AvvisoTimer {
  AudioPlayer? player;

  /// Ripete la vibrazione mentre l'allarme suona
  Timer? vibrazione;

  bool schermoTenutoAcceso = false;

  /// Lo schermo resta acceso mentre il timer è avviato: se il telefono si bloccasse,
  /// su iPhone l'app verrebbe sospesa e l'allarme non suonerebbe
  Future<void> schermoAcceso(bool acceso) async {
    if (acceso == schermoTenutoAcceso) {
      return;
    }
    schermoTenutoAcceso = acceso;
    if (acceso) {
      await WakelockPlus.enable();
    } else {
      await WakelockPlus.disable();
    }
  }

  /// Il suono si ripete finché non si chiama [fermaAllarme]
  Future<void> suonaAllarme() async {
    player ??= AudioPlayer();
    final audio = player!;

    // Il file è in lib/assets e non nella cartella predefinita assets/
    audio.audioCache = AudioCache(prefix: 'lib/assets/');
    // duckOthers: la musica che l'utente sta ascoltando si abbassa invece di fermarsi.
    // Con respectSilence a false l'allarme si sente anche con l'iPhone in modalità silenziosa
    await audio.setAudioContext(AudioContextConfig(focus: AudioContextConfigFocus.duckOthers).build());
    await audio.setReleaseMode(ReleaseMode.loop);
    await audio.play(AssetSource('allarme.wav'));

    HapticFeedback.vibrate();
    vibrazione?.cancel();
    vibrazione = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      HapticFeedback.vibrate();
    });
  }

  Future<void> fermaAllarme() async {
    vibrazione?.cancel();
    vibrazione = null;
    await player?.stop();
  }

  /// Libera altoparlante e schermo quando la pagina viene chiusa
  Future<void> chiudi() async {
    await fermaAllarme();
    await schermoAcceso(false);
    await player?.dispose();
    player = null;
  }
}
