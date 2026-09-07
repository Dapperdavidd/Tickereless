import 'package:tickerless/features/auth/domain/entities/auth_session.dart';

class AuthSessionModel extends AuthSession {
  const AuthSessionModel({
    required super.accessToken,
    required super.email,
    required super.userId,
  });

  factory AuthSessionModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>;
    return AuthSessionModel(
      accessToken: json['access_token'].toString(),
      email: user['email'].toString(),
      userId: user['id'].toString(),
    );
  }

  factory AuthSessionModel.fromUser(
    Map<String, dynamic> user,
    String accessToken,
  ) => AuthSessionModel(
    accessToken: accessToken,
    email: user['email'].toString(),
    userId: user['id'].toString(),
  );
}
