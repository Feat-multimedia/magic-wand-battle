import 'dart:io';
import 'package:flutter/material.dart';

import '../../services/sound_service.dart';
import '../../services/auth_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/common_widgets.dart';

/// Écran de gestion des sons pour les administrateurs
class SoundManagementScreen extends StatefulWidget {
  const SoundManagementScreen({super.key});

  @override
  State<SoundManagementScreen> createState() => _SoundManagementScreenState();
}

class _SoundManagementScreenState extends State<SoundManagementScreen> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎵 Gestion des Sons'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isUploading ? null : _showUploadDialog,
            tooltip: 'Ajouter un son',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isUploading) _buildUploadProgress(),
          Expanded(
            child: StreamBuilder<List<SoundFile>>(
              stream: SoundService.getSoundsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  );
                }

                final sounds = snapshot.data ?? [];

                if (sounds.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildSoundsList(sounds);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue.withValues(alpha: 0.1),
      child: Column(
        children: [
          Row(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadStatus,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _uploadProgress,
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toInt()}% terminé',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.library_music,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun son uploadé',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Commencez par uploader des fichiers audio\npour les utiliser dans vos sorts',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          HeroSoundButton(
            text: 'Uploader un Son',
            icon: Icons.upload,
            color: Colors.deepPurple,
            onPressed: _showUploadDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundsList(List<SoundFile> sounds) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return _buildSoundCard(sound);
      },
    );
  }

  Widget _buildSoundCard(SoundFile sound) {
    return SoundCard(
      onTap: () => _previewSound(sound),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône du fichier audio
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.audiotrack,
                color: Colors.deepPurple,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            
            // Informations du fichier
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sound.originalFileName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.file_download,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        SoundService.formatFileSize(sound.fileSizeBytes),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(sound.uploadedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Actions
            PopupMenuButton<String>(
              onSelected: (action) => _handleSoundAction(action, sound),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'preview',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow),
                      SizedBox(width: 8),
                      Text('Écouter'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'rename',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Renommer'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Supprimer', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      builder: (context) => _UploadSoundDialog(
        onUploadStarted: _handleUploadStarted,
        onUploadCompleted: _handleUploadCompleted,
      ),
    );
  }

  void _handleUploadStarted() {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Préparation de l\'upload...';
    });
  }

  void _handleUploadCompleted() {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
      _uploadStatus = '';
    });
  }

  void _previewSound(SoundFile sound) {
    // Jouer le son uploadé
    AudioService().playSoundFromUrl(sound.downloadUrl);
    
    SoundNotification.show(
      context,
      message: '🎵 Lecture de "${sound.name}"',
      sound: null, // Pas de son par défaut pour éviter le double son
    );
  }

  void _handleSoundAction(String action, SoundFile sound) {
    switch (action) {
      case 'preview':
        _previewSound(sound);
        break;
      case 'rename':
        _showRenameDialog(sound);
        break;
      case 'delete':
        _showDeleteConfirmation(sound);
        break;
    }
  }

  void _showRenameDialog(SoundFile sound) {
    // TODO: Implémenter le renommage
    SoundNotification.show(
      context,
      message: 'Renommage à implémenter',
    );
  }

  void _showDeleteConfirmation(SoundFile sound) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le son'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "${sound.name}" ?\n\n'
          'Cette action est irréversible et supprimera également '
          'le fichier du stockage.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSound(sound);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSound(SoundFile sound) async {
    final success = await SoundService.deleteSound(sound.id);
    
    if (mounted) {
      SoundNotification.show(
        context,
        message: success 
            ? '✅ Son "${sound.name}" supprimé'
            : '❌ Erreur lors de la suppression',
        backgroundColor: success ? Colors.green : Colors.red,
      );
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

/// Dialog pour uploader un nouveau son
class _UploadSoundDialog extends StatefulWidget {
  final VoidCallback onUploadStarted;
  final VoidCallback onUploadCompleted;

  const _UploadSoundDialog({
    required this.onUploadStarted,
    required this.onUploadCompleted,
  });

  @override
  State<_UploadSoundDialog> createState() => _UploadSoundDialogState();
}

class _UploadSoundDialogState extends State<_UploadSoundDialog> {
  final _nameController = TextEditingController();
  File? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('🎵 Uploader un Son'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélection du fichier
            const Text(
              'Fichier Audio',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            
            if (_selectedFile == null) ...[
              SoundButton(
                text: 'Choisir un fichier',
                icon: Icons.file_upload,
                onPressed: _pickFile,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                foregroundColor: Colors.blue,
              ),
              const SizedBox(height: 8),
              const Text(
                'Formats supportés: MP3, WAV, M4A, AAC\nTaille max: 5MB',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.audiotrack, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.path.split('/').last,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          FutureBuilder<int>(
                            future: _selectedFile!.length(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Text(
                                  SoundService.formatFileSize(snapshot.data!),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedFile = null),
                      icon: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Nom du son
            const Text(
              'Nom du Son',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Ex: Sort de Feu Épique',
                border: OutlineInputBorder(),
              ),
              enabled: !_isUploading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _canUpload() && !_isUploading ? _uploadSound : null,
          child: _isUploading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Uploader'),
        ),
      ],
    );
  }

  bool _canUpload() {
    return _selectedFile != null && _nameController.text.trim().isNotEmpty;
  }

  Future<void> _pickFile() async {
    final result = await SoundService.pickAudioFile();
    if (result != null && result.files.isNotEmpty) {
      final file = File(result.files.first.path!);
      
      // Valider le fichier
      if (!SoundService.isValidAudioFile(file.path)) {
        if (mounted) {
          SoundNotification.show(
            context,
            message: '❌ Format de fichier non supporté',
            backgroundColor: Colors.red,
          );
        }
        return;
      }
      
      final fileSize = await file.length();
      if (!SoundService.isValidFileSize(fileSize)) {
        if (mounted) {
          SoundNotification.show(
            context,
            message: '❌ Fichier trop volumineux (max 5MB)',
            backgroundColor: Colors.red,
          );
        }
        return;
      }
      
      setState(() {
        _selectedFile = file;
        // Auto-remplir le nom basé sur le fichier
        if (_nameController.text.isEmpty) {
          final fileName = file.path.split('/').last;
          final nameWithoutExtension = fileName.split('.').first;
          _nameController.text = nameWithoutExtension;
        }
      });
    }
  }

  Future<void> _uploadSound() async {
    if (!_canUpload()) return;
    
    setState(() => _isUploading = true);
    widget.onUploadStarted();
    
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');
      
      final soundFile = await SoundService.uploadSound(
        file: _selectedFile!,
        soundName: _nameController.text.trim(),
        uploadedBy: currentUser.displayName ?? currentUser.email ?? 'Inconnu',
        onProgress: (progress) {
          // TODO: Communiquer le progrès au parent
        },
      );
      
      if (soundFile != null) {
        if (mounted) {
          Navigator.pop(context);
          SoundNotification.show(
            context,
            message: '✅ Son "${soundFile.name}" uploadé avec succès !',
            backgroundColor: Colors.green,
          );
        }
      } else {
        throw Exception('Échec de l\'upload');
      }
      
    } catch (e) {
      if (mounted) {
        SoundNotification.show(
          context,
          message: '❌ Erreur lors de l\'upload: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
        widget.onUploadCompleted();
      }
    }
  }
} 