import 'package:flutter/material.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/features/panel/v2board/models/plan_model.dart';
import 'package:hiddify/features/panel/v2board/service/auth_service.dart';
import 'package:hiddify/features/panel/v2board/storage/token_storage.dart';
import 'package:hiddify/features/profile/data/profile_data_providers.dart';
import 'package:hiddify/features/profile/model/profile_entity.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class PurchaseService {
  Future<List<Plan>> fetchPlanData() async {
    final accessToken = await getToken();
    if (accessToken == null) {
      print("No access token found.");
      return [];
    }

    return await AuthService().fetchPlanData(accessToken);
  }

  Future<void> addSubscription(BuildContext context, String accessToken,
      WidgetRef ref, Function showSnackbar) async {
    final t = ref.watch(translationsProvider);
    try {
      final subscriptionLink =
          await AuthService().getSubscriptionLink(accessToken);
      if (subscriptionLink == null) {
        showSnackbar(context, t.purchase.noSubscriptionLink);
        return;
      }

      print("Adding subscription link: $subscriptionLink");

      await ref.read(addProfileProvider.notifier).add(subscriptionLink);

      final profileRepository =
          await ref.read(profileRepositoryProvider.future);
      final profilesResult = await profileRepository.watchAll().first;
      final profiles = profilesResult.getOrElse((_) => []);
      final newProfile = profiles.firstWhere(
        (profile) =>
            profile is RemoteProfileEntity && profile.url == subscriptionLink,
        orElse: () {
          if (profiles.isNotEmpty) {
            return profiles[0];
          } else {
            throw Exception("No profiles available");
          }
        },
      );

      ref.read(activeProfileProvider.notifier).update((_) => newProfile);

      showSnackbar(context, t.purchase.subscriptionAdded);
    } catch (e) {
      print(e);
      showSnackbar(context, "${t.purchase.addSubscriptionError} $e");
    }
  }

  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> createOrder(
      int planId, String period, String accessToken) async {
    return await _authService.createOrder(accessToken, planId, period);
  }

  Future<List<dynamic>> getPaymentMethods(String accessToken) async {
    return await _authService.getPaymentMethods(accessToken);
  }

  Future<String?> submitOrder(
      String tradeNo, String method, String accessToken) async {
    return await _authService.submitOrder(tradeNo, method, accessToken);
  }
}
