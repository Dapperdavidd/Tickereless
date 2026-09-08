import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:tickerless/features/auth/presentation/bloc/auth_state.dart';
import 'package:tickerless/features/profile/data/profile_identity_store.dart';
import 'package:tickerless/features/profile/presentation/widgets/profile_avatar.dart';

/// The signed-in person's saved avatar, shared by every profile entry point.
class CurrentProfileAvatar extends StatelessWidget {
  const CurrentProfileAvatar({this.size = 30, super.key});
  final double size;

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthBloc, AuthState>(
    buildWhen: (previous, current) =>
        previous.session != current.session || previous.mode != current.mode,
    builder: (context, auth) {
      final session = auth.session;
      if (session == null) {
        return ProfileAvatar(index: 0, size: size);
      }
      return FutureBuilder<ProfileIdentity>(
        future: ProfileIdentityStore().read(session.userId, session.email),
        builder: (context, snapshot) => ProfileAvatar(
          index: snapshot.data?.avatar ?? 0,
          photoPath: snapshot.data?.photoPath,
          size: size,
        ),
      );
    },
  );
}
