// views/domain_check_indicator.dart
import 'package:flutter/material.dart';
import 'package:hiddify/features/panel/xboard/viewmodels/domain_check_viewmodel.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final domainCheckViewModelProvider = ChangeNotifierProvider((ref) {
  return DomainCheckViewModel();
});

class DomainCheckIndicator extends ConsumerWidget {
  const DomainCheckIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainCheckViewModel = ref.watch(domainCheckViewModelProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (domainCheckViewModel.isChecking)
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(),
              ),
              const SizedBox(width: 4),
              Text(domainCheckViewModel.progressIndicator),
              const SizedBox(width: 8),
              Text('重试次数: ${domainCheckViewModel.retryCount}'),
            ],
          )
        else if (domainCheckViewModel.isSuccess)
          const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('检查通过'),
            ],
          )
        else
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 8),
              Text('连接失败 (重试次数: ${domainCheckViewModel.retryCount})'),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  domainCheckViewModel.retry();
                },
              ),
            ],
          ),
      ],
    );
  }
}
