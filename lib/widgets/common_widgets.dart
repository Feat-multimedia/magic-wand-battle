import 'package:flutter/material.dart';
import '../services/audio_service.dart';

/// Bouton avec son intégré
class SoundButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final IconData? icon;
  final bool enabled;
  final SoundType? customSound;

  const SoundButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.icon,
    this.enabled = true,
    this.customSound,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: enabled ? _handlePress : null,
      icon: icon != null ? Icon(icon) : const SizedBox.shrink(),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }

  void _handlePress() {
    // Jouer le son avant d'exécuter l'action
    AudioService().playSFX(customSound ?? SoundType.buttonClick);
    onPressed();
  }
}

/// Card interactive avec effets sonores
class SoundCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final double elevation;
  final SoundType? tapSound;

  const SoundCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.elevation = 2.0,
    this.tapSound,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: elevation,
      child: InkWell(
        onTap: onTap != null ? _handleTap : null,
        borderRadius: BorderRadius.circular(12),
        child: child,
      ),
    );
  }

  void _handleTap() {
    if (onTap == null) return;
    
    // Jouer le son avant d'exécuter l'action
    AudioService().playSFX(tapSound ?? SoundType.buttonClick);
    onTap!();
  }
}

/// Indicateur de progression avec effets sonores
class SoundProgressIndicator extends StatefulWidget {
  final double progress;
  final Color? color;
  final bool playProgressSounds;

  const SoundProgressIndicator({
    super.key,
    required this.progress,
    this.color,
    this.playProgressSounds = false,
  });

  @override
  State<SoundProgressIndicator> createState() => _SoundProgressIndicatorState();
}

class _SoundProgressIndicatorState extends State<SoundProgressIndicator> {
  double _lastProgress = 0.0;

  @override
  void didUpdateWidget(SoundProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.playProgressSounds && widget.progress > _lastProgress) {
      // Jouer un son à certains seuils
      if (_lastProgress < 0.25 && widget.progress >= 0.25) {
        AudioService().playSFX(SoundType.buttonClick, volume: 0.2);
      } else if (_lastProgress < 0.5 && widget.progress >= 0.5) {
        AudioService().playSFX(SoundType.buttonClick, volume: 0.3);
      } else if (_lastProgress < 0.75 && widget.progress >= 0.75) {
        AudioService().playSFX(SoundType.buttonClick, volume: 0.4);
      } else if (_lastProgress < 1.0 && widget.progress >= 1.0) {
        AudioService().playSFX(SoundType.whoosh, volume: 0.5);
      }
    }
    
    _lastProgress = widget.progress;
  }

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: widget.progress,
      color: widget.color,
      backgroundColor: widget.color?.withValues(alpha: 0.3),
    );
  }
}

/// Switch avec effets sonores
class SoundSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;

  const SoundSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: _handleChange,
    );
  }

  void _handleChange(bool newValue) {
    // Son différent selon l'état
    if (newValue) {
      AudioService().playSFX(SoundType.spellSuccess, volume: 0.3);
    } else {
      AudioService().playSFX(SoundType.buttonClick, volume: 0.3);
    }
    
    onChanged(newValue);
  }
}

/// Slider avec feedback audio
class SoundSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final String label;
  final bool provideFeedback;

  const SoundSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    required this.label,
    this.provideFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: _handleChange,
          onChangeEnd: _handleChangeEnd,
        ),
      ],
    );
  }

  void _handleChange(double newValue) {
    onChanged(newValue);
  }

  void _handleChangeEnd(double finalValue) {
    if (provideFeedback) {
      // Jouer un son de test avec le volume sélectionné
      AudioService().playSFX(SoundType.buttonClick, volume: finalValue);
    }
  }
}

/// Notification animée avec son
class SoundNotification {
  static void show(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    SoundType? sound,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Jouer le son
    if (sound != null) {
      AudioService().playSFX(sound);
    } else {
      AudioService().playSFX(SoundType.notification);
    }

    // Afficher la notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Bouton d'action principale avec effets dramatiques
class HeroSoundButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const HeroSoundButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.icon,
    required this.color,
    this.isLoading = false,
  });

  @override
  State<HeroSoundButton> createState() => _HeroSoundButtonState();
}

class _HeroSoundButtonState extends State<HeroSoundButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.isLoading ? null : _handlePress,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: widget.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.text,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handlePress() {
    // Animation tactile
    _controller.forward().then((_) {
      _controller.reverse();
    });

    // Effets sonores dramatiques
    AudioService().playSFX(SoundType.whoosh, volume: 0.6);
    
    widget.onPressed();
  }
} 