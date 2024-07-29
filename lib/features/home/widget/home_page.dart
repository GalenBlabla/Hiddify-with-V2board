import 'package:dartx/dartx.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hiddify/core/app_info/app_info_provider.dart';
import 'package:hiddify/core/localization/translations.dart';
import 'package:hiddify/core/model/failures.dart';
import 'package:hiddify/core/router/router.dart';
import 'package:hiddify/features/common/nested_app_bar.dart';
import 'package:hiddify/features/home/widget/connection_button.dart';
import 'package:hiddify/features/home/widget/empty_profiles_home_body.dart';
import 'package:hiddify/features/profile/notifier/active_profile_notifier.dart';
import 'package:hiddify/features/profile/widget/profile_tile.dart';
import 'package:hiddify/features/proxy/active/active_proxy_delay_indicator.dart';
import 'package:hiddify/features/proxy/active/active_proxy_footer.dart';
import 'package:hiddify/utils/utils.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:hiddify/storage/token_storage.dart';
import 'package:hiddify/features/profile/notifier/profile_notifier.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_hooks/flutter_hooks.dart';

class HomePage extends HookConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final hasAnyProfile = ref.watch(hasAnyProfileProvider);
    final activeProfile = ref.watch(activeProfileProvider);
    final plans = useState<List<dynamic>>([]);

    useEffect(() {
      Future<void> checkAndAddSubscription() async {
        final token = await getToken();
        if (token != null) {
          final subscriptionLink = await _getSubscriptionLink(token);
          if (subscriptionLink != null && subscriptionLink.isNotEmpty) {
            final isValid = await _checkSubscriptionLink(subscriptionLink);
            if (isValid) {
              await _addSubscription(context, ref, subscriptionLink);
            } else {
              plans.value = await _fetchPlans(token);
            }
          } else {
            plans.value = await _fetchPlans(token);
          }
        }
      }

      checkAndAddSubscription();

      return null;
    }, []);

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomScrollView(
            slivers: [
              NestedAppBar(
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: t.general.appTitle),
                      const TextSpan(text: " "),
                      const WidgetSpan(
                        child: AppVersionLabel(),
                        alignment: PlaceholderAlignment.middle,
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () => const QuickSettingsRoute().push(context),
                    icon: const Icon(FluentIcons.options_24_filled),
                    tooltip: t.config.quickSettings,
                  ),
                  IconButton(
                    onPressed: () => const AddProfileRoute().push(context),
                    icon: const Icon(FluentIcons.add_circle_24_filled),
                    tooltip: t.profile.add.buttonText,
                  ),
                ],
              ),
              if (plans.value.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (BuildContext context, int index) {
                      final plan = plans.value[index];
                      return ListTile(
                        title: Text(plan['name']),
                        subtitle: Text(plan['content']),
                        trailing: Text("\$${plan['onetime_price'] / 100}"),
                        onTap: () {
                          // 处理用户选择套餐计划的逻辑
                        },
                      );
                    },
                    childCount: plans.value.length,
                  ),
                )
              else
                switch (activeProfile) {
                  AsyncData(value: final profile?) => MultiSliver(
                      children: [
                        ProfileTile(profile: profile, isMain: true),
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ConnectionButton(),
                                    ActiveProxyDelayIndicator(),
                                  ],
                                ),
                              ),
                              if (MediaQuery.sizeOf(context).width < 840)
                                const ActiveProxyFooter(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  AsyncData() => switch (hasAnyProfile) {
                      AsyncData(value: true) =>
                        const EmptyActiveProfileHomeBody(),
                      _ => const EmptyProfilesHomeBody(),
                    },
                  AsyncError(:final error) =>
                    SliverErrorBodyPlaceholder(t.presentShortError(error)),
                  _ => const SliverToBoxAdapter(),
                },
            ],
          ),
        ],
      ),
    );
  }

  Future<String?> _getSubscriptionLink(String accessToken) async {
    final url = Uri.parse("https://clarityvpn.xyz/api/v1/user/getSubscribe");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        print("Subscription link retrieved successfully");
        return data["data"]["subscribe_url"];
      } else {
        print("Failed to retrieve subscription link: ${data["message"]}");
        return null;
      }
    } else {
      print("Failed to retrieve subscription link: ${response.statusCode}");
      return null;
    }
  }

  Future<bool> _checkSubscriptionLink(String subscriptionLink) async {
    final response = await http.get(Uri.parse(subscriptionLink));

    if (response.statusCode == 200) {
      final data = response.body;
      if (data.isNotEmpty) {
        return true;
      } else {
        print("Subscription link returned empty data");
        return false;
      }
    } else {
      print("Failed to validate subscription link: ${response.statusCode}");
      return false;
    }
  }

  Future<void> _addSubscription(BuildContext context, WidgetRef ref, String subscriptionLink) async {
    final addProfileNotifier = ref.read(addProfileProvider.notifier);

    try {
      print("Attempting to add subscription: $subscriptionLink");
      await addProfileNotifier.add(subscriptionLink);
      if (context.mounted) {
        _showSuccessSnackbar(context, "Subscription added successfully");
      }
    } catch (error) {
      print("Error adding subscription: $error");
      if (context.mounted) {
        _showErrorSnackbar(context, "Failed to add subscription");
      }
    }
  }

  Future<List<dynamic>> _fetchPlans(String accessToken) async {
    final url = Uri.parse("https://clarityvpn.xyz/api/v1/user/plan/fetch");
    final response = await http.get(
      url,
      headers: {'Authorization': accessToken},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data["status"] == "success") {
        return data["data"];
      } else {
        print("Failed to retrieve plans: ${data["message"]}");
        return [];
      }
    } else {
      print("Failed to retrieve plans: ${response.statusCode}");
      return [];
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}

class AppVersionLabel extends HookConsumerWidget {
  const AppVersionLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);
    final theme = Theme.of(context);

    final version = ref.watch(appInfoProvider).requireValue.presentVersion;
    if (version.isBlank) return const SizedBox();

    return Semantics(
      label: t.about.version,
      button: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        child: Text(
          version,
          textDirection: TextDirection.ltr,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
