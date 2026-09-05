import 'package:flutter/material.dart';

import '../models/company.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import 'experience_screens.dart';

class FunctionalLinkScreen extends StatefulWidget {
  const FunctionalLinkScreen({super.key});
  @override
  State<FunctionalLinkScreen> createState() => _FunctionalLinkScreenState();
}

class _FunctionalLinkScreenState extends State<FunctionalLinkScreen> {
  final controller = TextEditingController(
    text: 'https://www.nvidia.com/en-us/',
  );
  final api = TickerlessApi();
  List<CompanyMatch> matches = const [
    CompanyMatch(
      company: DemoCompanies.nvidia,
      reason: 'Primary subject · AI hardware',
      confidence: .92,
    ),
    CompanyMatch(
      company: DemoCompanies.alphabet,
      reason: 'Mentioned in the article',
      confidence: .24,
    ),
  ];
  bool loading = false;
  String? error;

  Future<void> analyze() async {
    final url = controller.text.trim();
    if (url.isEmpty) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await api.link(url);
      if (mounted) setState(() => matches = result);
    } catch (failure) {
      if (mounted) setState(() => error = failure.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Link Analysis', style: TextStyle(fontSize: 15)),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          onSubmitted: (_) => analyze(),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.link),
            suffixIcon: IconButton(
              onPressed: analyze,
              icon: const Icon(Icons.arrow_upward),
            ),
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          onTap: loading ? null : analyze,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF111C23),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.memory,
                  color: Color(0xFF9BFF00),
                  size: 34,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NVIDIA',
                      style: TextStyle(color: AppColors.muted, fontSize: 10),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'The next generation of AI computing',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: loading ? null : analyze,
          child: Text(loading ? 'Analyzing…' : 'Analyze Link'),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text(error!, style: const TextStyle(color: AppColors.red)),
          ),
        const SizedBox(height: 24),
        const Text(
          'Companies detected',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        if (!loading && matches.isEmpty)
          const GlassCard(
            child: Text('No supported companies were detected on this page.'),
          ),
        ...matches.map(
          (match) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              onTap: () => openScreen(
                context,
                PassportScreen(
                  company: match.company,
                  source: '${controller.text.trim()} · Link',
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: match.company.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _companyIcon(match.company),
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          match.company.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          match.reason,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${match.company.symbol} · Base Sepolia',
                          style: const TextStyle(
                            color: AppColors.blue,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${(match.confidence * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 14, color: AppColors.muted),
            SizedBox(width: 6),
            Text(
              'Powered by the Tickerless resolver',
              style: TextStyle(color: AppColors.muted, fontSize: 11),
            ),
          ],
        ),
      ],
    ),
  );
}

IconData _companyIcon(Company company) => switch (company.ticker) {
  'AAPL' => Icons.apple,
  'META' => Icons.all_inclusive,
  'GOOGL' => Icons.g_mobiledata,
  _ => Icons.memory,
};
