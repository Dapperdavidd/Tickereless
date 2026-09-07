import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/flow_scaffold.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/features/discovery/data/registry/demo_companies.dart';
import 'package:tickerless/features/discovery/domain/entities/company_match.dart';
import 'package:tickerless/features/discovery/domain/entities/discovery_source.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_bloc.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_event.dart';
import 'package:tickerless/features/discovery/presentation/bloc/search_state.dart';
import 'package:tickerless/features/discovery/presentation/widgets/company_result_card.dart';

/// Ask in plain language; get the company behind the answer.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController(text: 'company behind instagram');

  /// Shown before the first query, so the screen explains itself rather than
  /// opening empty.
  static const _example = CompanyMatch(
    company: DemoCompanies.meta,
    reason: 'Instagram is a product of Meta Platforms',
    confidence: .98,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() =>
      context.read<SearchBloc>().add(SearchSubmitted(_controller.text));

  void _openPassport(CompanyMatch match, String query) => context.push(
    AppRoutes.passport,
    extra: PassportArgs(
      company: match.company,
      source: DiscoverySource.search.describe('“$query”'),
    ),
  );

  @override
  Widget build(BuildContext context) => FlowScaffold(
    title: 'Search',
    child: BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _controller,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_upward),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _ProductHint(),
          const SizedBox(height: 24),
          if (state is SearchLoading)
            const Center(child: CircularProgressIndicator()),
          if (state is SearchFailed)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.message,
                style: const TextStyle(color: AppColors.red),
              ),
            ),
          if (state is SearchLoaded && state.matches.isEmpty)
            const Text(
              'Nothing matched that. Try describing the thing itself.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
          HairlineList(
            gap: 30,
            children: switch (state) {
              SearchLoaded(:final matches, :final query) => [
                for (final match in matches) _result(match, query),
              ],
              _ => [_result(_example, _controller.text.trim())],
            },
          ),
          const SizedBox(height: 30),
          const Text(
            'Related results',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          const _RelatedRow(
            icon: Icons.facebook,
            title: 'Facebook',
            subtitle: 'A product of Meta',
          ),
          const _RelatedRow(
            icon: Icons.message,
            title: 'WhatsApp',
            subtitle: 'A product of Meta',
          ),
          const _RelatedRow(
            icon: Icons.alternate_email,
            title: 'Threads',
            subtitle: 'A product of Meta',
          ),
        ],
      ),
    ),
  );

  Widget _result(CompanyMatch match, String query) =>
      CompanyResultCard(match: match, onTap: () => _openPassport(match, query));
}

class _ProductHint extends StatelessWidget {
  const _ProductHint();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      CircleAvatar(
        radius: 21,
        backgroundColor: Color(0xFFE94592),
        child: Icon(Icons.camera_alt_outlined, color: Colors.white, size: 21),
      ),
      SizedBox(width: 13),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Instagram',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            SizedBox(height: 2),
            Text(
              'A product of Meta Platforms',
              style: TextStyle(color: AppColors.blue, fontSize: 11.5),
            ),
          ],
        ),
      ),
    ],
  );
}

class _RelatedRow extends StatelessWidget {
  const _RelatedRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: AppColors.blue),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right),
  );
}
