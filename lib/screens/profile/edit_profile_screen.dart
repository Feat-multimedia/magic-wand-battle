import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../utils/logger.dart';
import '../../widgets/common_widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  
  File? _selectedImage;
  bool _isUploading = false;
  bool _isSaving = false;
  String? _currentPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  void _loadCurrentUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.userProfile;
    
    if (user != null) {
      _displayNameController.text = user.displayName ?? '';
      _currentPhotoUrl = user.photoURL;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Éditer le Profil'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sauver', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  // Header Edition Profil
                  _buildEditProfileHeader(),
                  const SizedBox(height: 40),
                  
                  // Formulaire d'édition
                  _buildEditForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icon Edition avec effet
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF3B82F6),
                  Color(0xFF8B5CF6),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(
              Icons.edit,
              size: 48,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          
          // Titre
          Text(
            'Éditer le Profil',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 32,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Personnalisez votre identité de sorcier',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 18,
              color: const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de profil
          _buildPhotoSection(),
          const SizedBox(height: 32),
          
          // Nom d'affichage
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'affichage',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
              helperText: 'Ce nom sera visible par les autres joueurs',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom d\'affichage est requis';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              if (value.trim().length > 30) {
                return 'Le nom ne peut pas dépasser 30 caractères';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 24),
          
          // Bio (optionnel)
          TextFormField(
            controller: _bioController,
            decoration: const InputDecoration(
              labelText: 'Bio (optionnel)',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
              helperText: 'Parlez-nous de votre style de magie...',
            ),
            maxLines: 3,
            maxLength: 150,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          // Avatar actuel ou nouveau
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: _getAvatarImage(),
                child: _getAvatarImage() == null
                    ? Icon(
                        Icons.person,
                        size: 60,
                        color: Colors.grey.shade600,
                      )
                    : null,
              ),
              
              // Badge d'upload en cours
              if (_isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(60),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Boutons de gestion photo
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Caméra'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
              
              const SizedBox(width: 12),
              
              ElevatedButton.icon(
                onPressed: _isUploading ? null : () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galerie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          if (_currentPhotoUrl != null || _selectedImage != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _isUploading ? null : _removePhoto,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('Supprimer la photo', style: TextStyle(color: Colors.red)),
            ),
          ],
        ],
      ),
    );
  }

  ImageProvider? _getAvatarImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return NetworkImage(_currentPhotoUrl!);
    }
    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      Logger.error('Erreur sélection image', error: e);
      if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la sélection de l\'image');
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedImage = null;
      _currentPhotoUrl = null;
    });
  }

  Future<String?> _uploadPhoto() async {
    if (_selectedImage == null) return _currentPhotoUrl;

    setState(() => _isUploading = true);

    try {
      final userId = AuthService.currentUser?.uid;
      if (userId == null) throw Exception('Utilisateur non connecté');

      // Référence Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_photos')
          .child('$userId.jpg');

      // Upload
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      Logger.success('Photo uploadée: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      Logger.error('Erreur upload photo', error: e);
      if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de l\'upload de la photo');
      }
      return _currentPhotoUrl;
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload de la photo si nécessaire
      final photoUrl = await _uploadPhoto();

      // 2. Mise à jour du profil
      final success = await AuthService.updateUserProfile(
        displayName: _displayNameController.text.trim(),
        photoURL: photoUrl,
      );

      if (success && mounted) {
        // 3. Actualiser le provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.refreshUserProfile();

        // 4. Retour à l'écran précédent
        context.pop();
        SoundNotification.show(context, message: '✅ Profil mis à jour avec succès !');
      } else if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la mise à jour');
      }
    } catch (e) {
      Logger.error('Erreur sauvegarde profil', error: e);
      if (mounted) {
        SoundNotification.show(context, message: '❌ Erreur lors de la sauvegarde');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
} 