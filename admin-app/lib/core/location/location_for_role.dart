import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sapbaq_admin/core/location/location_service.dart';
import 'package:sapbaq_admin/features/auth/presentation/bloc/auth_bloc.dart';

/// The [LocationService] a queue cubit should use — or null for the roles that
/// aren't asked for their location at all.
///
/// Nearest-first sorting exists for the people who drive between mosques (the
/// team leader and the handler). Prompting the dispatch desk or a manager, who
/// work from a desk, would cost them a permission dialog and change nothing on
/// screen — so those roles get null and the server's default order.
LocationService? locationForRole(BuildContext context) {
  final user = context.read<AuthBloc>().state.user;
  if (user?.isFieldRole != true) return null;
  return context.read<LocationService>();
}
