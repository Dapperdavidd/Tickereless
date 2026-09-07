import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class ProfileIdentity {
  const ProfileIdentity({
    required this.name,
    required this.avatar,
    this.photoPath,
  });
  final String name;
  final int avatar;
  final String? photoPath;
}

class ProfileIdentityStore {
  ProfileIdentityStore({FlutterSecureStorage? storage, ImagePicker? picker})
    : _storage = storage ?? const FlutterSecureStorage(),
      _picker = picker ?? ImagePicker();

  final FlutterSecureStorage _storage;
  final ImagePicker _picker;

  String _key(String userId, String field) =>
      'tickerless_profile_${userId}_$field';

  Future<ProfileIdentity> read(String userId, String email) async {
    final name = await _storage.read(key: _key(userId, 'name'));
    final avatar =
        int.tryParse(await _storage.read(key: _key(userId, 'avatar')) ?? '') ??
        0;
    final photoPath = await _storage.read(key: _key(userId, 'photo'));
    return ProfileIdentity(
      name: name?.trim().isNotEmpty == true ? name! : email.split('@').first,
      avatar: avatar.clamp(0, 5),
      photoPath: photoPath,
    );
  }

  Future<void> save(String userId, ProfileIdentity identity) async {
    await _storage.write(
      key: _key(userId, 'name'),
      value: identity.name.trim(),
    );
    await _storage.write(
      key: _key(userId, 'avatar'),
      value: identity.avatar.toString(),
    );
    await _storage.write(key: _key(userId, 'photo'), value: identity.photoPath);
  }

  Future<String?> pickPhoto(String userId) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1200,
    );
    if (picked == null) return null;
    final directory = await getApplicationSupportDirectory();
    final extension = picked.path.split('.').last;
    final destination = File('${directory.path}/profile-$userId.$extension');
    await File(picked.path).copy(destination.path);
    return destination.path;
  }
}
