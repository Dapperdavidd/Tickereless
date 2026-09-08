import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
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
  final _controller = TextEditingController();

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
        final matches = state is LinkAnalyzed ? state.matches : const [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextField(
              controller: _controller,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              onSubmitted: (_) => _analyze(),
              decoration: InputDecoration(
                hintText: 'Paste an article or website URL',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  onPressed: _analyze,
                  icon: const Icon(Icons.arrow_upward),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (state is LinkInitial) ...[
              const Text(
                'Tickerless reads the public page and identifies supported companies from its actual content.',
                style: TextStyle(color: AppColors.muted, height: 1.5),
              ),
              const SizedBox(height: 12),
            ],
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
            if (state is LinkAnalyzed && matches.isEmpty)
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
