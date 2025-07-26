import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';

import '../utils/logger.dart';

/// Modèle pour un son uploadé
class SoundFile {
  final String id;
  final String name;
  final String originalFileName;
  final String downloadUrl;
  final int fileSizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;

  SoundFile({
    required this.id,
    required this.name,
    required this.originalFileName,
    required this.downloadUrl,
    required this.fileSizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  factory SoundFile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SoundFile(
      id: doc.id,
      name: data['name'] ?? '',
      originalFileName: data['originalFileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      uploadedBy: data['uploadedBy'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'originalFileName': originalFileName,
      'downloadUrl': downloadUrl,
      'fileSizeBytes': fileSizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
    };
  }
}

/// Service pour gérer les sons uploadés
class SoundService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _soundsCollection = 'sounds';
  static const String _storagePath = 'sounds';

  /// Récupérer tous les sons disponibles
  static Future<List<SoundFile>> getAllSounds() async {
    try {
      final snapshot = await _firestore
          .collection(_soundsCollection)
          .orderBy('uploadedAt', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => SoundFile.fromFirestore(doc)).toList();
    } catch (e) {
      Logger.error(' Erreur récupération sons: $e');
      return [];
    }
  }

  /// Stream des sons pour mise à jour temps réel
  static Stream<List<SoundFile>> getSoundsStream() {
    return _firestore
        .collection(_soundsCollection)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SoundFile.fromFirestore(doc))
            .toList());
  }

  /// Ouvre le sélecteur de fichier pour choisir un fichier audio
  static Future<FilePickerResult?> pickAudioFile() async {
    try {
      return await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
      );
    } catch (e) {
      Logger.error(' Erreur sélection fichier: $e');
      return null;
    }
  }

  /// Upload un fichier audio vers Firebase Storage
  static Future<SoundFile?> uploadSound({
    required File file,
    required String soundName,
    required String uploadedBy,
    Function(double)? onProgress,
  }) async {
    try {
      // Générer un ID unique
      final soundId = const Uuid().v4();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last;
      final storagePath = '$_storagePath/$soundId.$fileExtension';

      // Upload vers Firebase Storage
      final storageRef = _storage.ref().child(storagePath);
      final uploadTask = storageRef.putFile(file);

      // Écouter la progression
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Créer l'objet SoundFile
      final soundFile = SoundFile(
        id: soundId,
        name: soundName,
        originalFileName: fileName,
        downloadUrl: downloadUrl,
        fileSizeBytes: await file.length(),
        uploadedAt: DateTime.now(),
        uploadedBy: uploadedBy,
      );

      // Sauvegarder les métadonnées dans Firestore
      await _firestore
          .collection(_soundsCollection)
          .doc(soundId)
          .set(soundFile.toFirestore());

      Logger.success(' Son uploadé avec succès: $soundName', tag: LogTags.firebase);
      return soundFile;

    } catch (e) {
      Logger.error(' Erreur upload son: $e');
      return null;
    }
  }

  /// Supprimer un son (fichier + métadonnées)
  static Future<bool> deleteSound(String soundId) async {
    try {
      // Récupérer les infos du son
      final doc = await _firestore.collection(_soundsCollection).doc(soundId).get();
      if (!doc.exists) return false;

      final soundFile = SoundFile.fromFirestore(doc);
      
      // Supprimer le fichier de Storage
      final fileExtension = soundFile.originalFileName.split('.').last;
      final storagePath = '$_storagePath/$soundId.$fileExtension';
      await _storage.ref().child(storagePath).delete();

      // Supprimer les métadonnées de Firestore
      await _firestore.collection(_soundsCollection).doc(soundId).delete();

      Logger.success(' Son supprimé: ${soundFile.name}', tag: LogTags.firebase);
      return true;

    } catch (e) {
      Logger.error(' Erreur suppression son: $e');
      return false;
    }
  }

  /// Récupérer un son par son ID
  static Future<SoundFile?> getSoundById(String soundId) async {
    try {
      final doc = await _firestore.collection(_soundsCollection).doc(soundId).get();
      if (doc.exists) {
        return SoundFile.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      Logger.error(' Erreur récupération son: $e');
      return null;
    }
  }

  /// Obtenir la taille formatée d'un fichier
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Valider qu'un fichier est un format audio supporté
  static bool isValidAudioFile(String fileName) {
    final validExtensions = ['mp3', 'wav', 'm4a', 'aac'];
    final extension = fileName.split('.').last.toLowerCase();
    return validExtensions.contains(extension);
  }

  /// Valider la taille du fichier (max 5MB)
  static bool isValidFileSize(int bytes) {
    const maxSize = 5 * 1024 * 1024; // 5MB
    return bytes <= maxSize;
  }
} 