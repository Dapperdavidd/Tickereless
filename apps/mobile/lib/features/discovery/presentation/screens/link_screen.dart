import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/link_state.dart';
import 'package:tickerless/features/discovery/presentation/widgets/detected_company_row.dart';

/// Paste anything with a URL and find out whose business it is.
class LinkScreen extends StatefulWidget {
  const LinkScreen({super.key});

  @override
  State<LinkScreen> createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  final _controller = TextEditingController(
    text: 'https://www.nvidia.com/en-us/',
  );

  /// What the screen shows before the first analysis — a worked example, not
  /// a claim about the URL in the field.
  static const _example = [
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _analyze() =>
      context.read<LinkBloc>().add(LinkSubmitted(_controller.text));

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Link Analysis', style: TextStyle(fontSize: 15)),
    ),
    body: BlocBuilder<LinkBloc, LinkState>(
      builder: (context, state) {
        final analyzing = state is LinkAnalyzing;
        final matches = state is LinkAnalyzed ? state.matches : _example;

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _analyze(),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  onPressed: _analyze,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: analyzing ? null : _analyze,
              behavior: HitTestBehavior.opaque,
              child: const Row(
                children: [
                  _PagePreviewThumb(),
                  SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NVIDIA',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 10.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'The next generation of AI computing',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: AppColors.muted,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: analyzing ? null : _analyze,
              child: Text(analyzing ? 'Analyzing…' : 'Analyze Link'),
            ),
            if (state is LinkFailed)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
            const SizedBox(height: 24),
            const Text(
              'Companies detected',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (!analyzing && matches.isEmpty)
              const Text(
                'No supported companies were detected on this page.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
            HairlineList(
              children: [
                for (final match in matches)
                  DetectedCompanyRow(
                    match: match,
                    onTap: () => context.push(
                      AppRoutes.passport,
                      extra: PassportArgs(
                        company: match.company,
                        source: DiscoverySource.link.describe(
                          _controller.text.trim(),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            const _ResolverFootnote(),
          ],
        );
      },
    ),
  );
}

class _PagePreviewThumb extends StatelessWidget {
  const _PagePreviewThumb();

  @override
  Widget build(BuildContext context) => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      color: const Color(0xFF9BFF00).withValues(alpha: .13),
      borderRadius: BorderRadius.circular(14),
    ),
    child: const Icon(Icons.memory, color: Color(0xFF9BFF00), size: 30),
  );
}

class _ResolverFootnote extends StatelessWidget {
  const _ResolverFootnote();

  @override
  Widget build(BuildContext context) => const Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.verified_outlined, size: 14, color: AppColors.muted),
      SizedBox(width: 6),
      Text(
        'Powered by the Tickerless resolver',
        style: TextStyle(color: AppColors.muted, fontSize: 11),
      ),
    ],
  );
}
