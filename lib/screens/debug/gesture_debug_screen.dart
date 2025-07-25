import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';
import '../../models/spell_model.dart';
import '../../services/gesture_service.dart';

class GestureDebugScreen extends StatefulWidget {
  const GestureDebugScreen({super.key});

  @override
  State<GestureDebugScreen> createState() => _GestureDebugScreenState();
}

class _GestureDebugScreenState extends State<GestureDebugScreen> {
  List<Point<double>> _currentPath = [];
  List<Point<double>> _referencePath = [];
  GestureData? _recordedGesture;
  bool _isRecording = false;
  
  @override
  void dispose() {
    GestureService.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _currentPath.clear();
    });

    GestureService.startRecording(
      onGestureRecorded: (gesture) {
        setState(() {
          _recordedGesture = gesture;
          _isRecording = false;
          _referencePath = List.from(_currentPath);
        });
        print('📊 Référence enregistrée: ${_referencePath.length} points visuels');
      },
      onRecordingProgress: (progress) {
        // Le progrès est maintenant en pourcentage (0-100)
      },
      onPositionUpdate: (position) {
        // 🎨 VRAIES DONNÉES DES CAPTEURS !
        setState(() {
          _currentPath.add(position);
          // Limiter pour la performance
          if (_currentPath.length > 300) {
            _currentPath.removeAt(0);
          }
        });
      },
    );
  }

  void _stopRecording() {
    if (_isRecording) {
      GestureService.stopRecording();
    }
  }

  void _testGesture() {
    if (_recordedGesture == null) return;

    setState(() {
      _currentPath.clear();
      _isRecording = true;
    });

    GestureService.startRecording(
      onGestureRecorded: (testGesture) {
        final similarity = GestureService.compareGestures(testGesture, _recordedGesture!);
        
        print('🎯 Test terminé: ${_currentPath.length} points visuels');
        print('🔍 Similarité: ${(similarity * 100).toStringAsFixed(1)}%');
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Similarité: ${(similarity * 100).toStringAsFixed(1)}%'),
            backgroundColor: similarity >= 0.5 ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
        
        setState(() {
          _isRecording = false;
        });
      },
      onRecordingProgress: (progress) {
        // Le progrès est maintenant en pourcentage
      },
      onPositionUpdate: (position) {
        // 🎨 VRAIES DONNÉES DES CAPTEURS POUR LE TEST !
        setState(() {
          _currentPath.add(position);
          // Limiter pour la performance
          if (_currentPath.length > 300) {
            _currentPath.removeAt(0);
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        title: const Text('Debug Gestes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF16213E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Zone de visualisation
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: CustomPaint(
                painter: GesturePainter(
                  currentPath: _currentPath,
                  referencePath: _referencePath,
                ),
                child: Container(),
              ),
            ),
          ),
          
          // Informations
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_recordedGesture != null) ...[
                  Text(
                    'Geste de référence enregistré',
                    style: TextStyle(color: Colors.green.shade300, fontSize: 16),
                  ),
                  Text(
                    'Points: ${_referencePath.length}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Points actuels: ${_currentPath.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                if (_isRecording)
                  const Text(
                    '🔴 ENREGISTREMENT...',
                    style: TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          
          // Boutons de contrôle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isRecording ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_isRecording ? 'Arrêter' : 'Enregistrer Réf'),
                ),
                
                if (_recordedGesture != null)
                  ElevatedButton(
                    onPressed: _isRecording ? null : _testGesture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Tester Geste'),
                  ),
                
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentPath.clear();
                      _referencePath.clear();
                      _recordedGesture = null;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GesturePainter extends CustomPainter {
  final List<Point<double>> currentPath;
  final List<Point<double>> referencePath;

  GesturePainter({
    required this.currentPath,
    required this.referencePath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner la grille
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;

    for (int i = 0; i < size.width; i += 50) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        gridPaint,
      );
    }
    for (int i = 0; i < size.height; i += 50) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        gridPaint,
      );
    }

    // Dessiner le geste de référence (en bleu)
    if (referencePath.length > 1) {
      final referencePaint = Paint()
        ..color = Colors.blue.withOpacity(0.7)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      final referencePath2 = Path();
      referencePath2.moveTo(referencePath.first.x, referencePath.first.y);
      for (int i = 1; i < referencePath.length; i++) {
        referencePath2.lineTo(referencePath[i].x, referencePath[i].y);
      }
      canvas.drawPath(referencePath2, referencePaint);
      
      // Point de départ (bleu)
      canvas.drawCircle(
        Offset(referencePath.first.x, referencePath.first.y),
        8,
        Paint()..color = Colors.blue,
      );
    }

    // Dessiner le geste actuel (en rouge)
    if (currentPath.length > 1) {
      final currentPaint = Paint()
        ..color = Colors.red
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      final currentPath2 = Path();
      currentPath2.moveTo(currentPath.first.x, currentPath.first.y);
      for (int i = 1; i < currentPath.length; i++) {
        currentPath2.lineTo(currentPath[i].x, currentPath[i].y);
      }
      canvas.drawPath(currentPath2, currentPaint);
      
      // Point de départ (rouge)
      canvas.drawCircle(
        Offset(currentPath.first.x, currentPath.first.y),
        6,
        Paint()..color = Colors.red,
      );
    }

    // Légende
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    
    textPainter.text = const TextSpan(
      text: 'Bleu: Référence | Rouge: Test',
      style: TextStyle(color: Colors.black, fontSize: 12),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 