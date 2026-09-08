import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:tickerless/core/router/app_router.dart';
import 'package:tickerless/core/router/route_args.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/flow_scaffold.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
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
  final _controller = TextEditingController();

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
              hintText: 'What company is behind Instagram?',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                onPressed: _submit,
                icon: const Icon(Icons.arrow_upward),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (state is SearchInitial) ...[
            const Text(
              'Ask about a product, brand, technology, or company. Results only appear after the resolver answers.',
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 24),
          ],
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
              _ => const [],
            },
          ),
        ],
      ),
    ),
  );

  Widget _result(CompanyMatch match, String query) =>
      CompanyResultCard(match: match, onTap: () => _openPassport(match, query));
}
