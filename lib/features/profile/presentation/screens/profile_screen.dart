import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          if (state is ProfileLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProfileError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.read<ProfileCubit>().loadProfile(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is ProfileLoaded) {
            final profile = state.profile;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // ── Avatar ──────────────────────────────────────
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Text(
                            profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 36),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Info Tiles ──────────────────────────────────
                _buildInfoTile(Icons.person, 'Name', profile.name),
                _buildInfoTile(Icons.email, 'Email', profile.email),
                if (profile.phone != null)
                  _buildInfoTile(Icons.phone, 'Phone', profile.phone!),
                if (profile.bio != null)
                  _buildInfoTile(Icons.info_outline, 'Bio', profile.bio!),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
