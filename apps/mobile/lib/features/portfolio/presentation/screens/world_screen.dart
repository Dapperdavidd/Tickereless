import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:tickerless/core/theme/app_theme.dart';
import 'package:tickerless/core/widgets/hairline_list.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_bloc.dart';
import 'package:tickerless/features/portfolio/presentation/bloc/portfolio_state.dart';
import 'package:tickerless/features/portfolio/presentation/widgets/position_row.dart';
import 'package:tickerless/features/portfolio/presentation/widgets/tab_list.dart';

/// Everything the user owns, and how they came to own it.
class WorldScreen extends StatelessWidget {
  const WorldScreen({super.key});

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PortfolioBloc, PortfolioState>(
    builder: (context, state) => TabList(
      title: 'Your World',
      subtitle: switch (state) {
        PortfolioLoaded() =>
          '${state.positions.length} companies · ${state.discoveryCount} discoveries · '
              '\$${state.total.toStringAsFixed(2)}',
        PortfolioError(:final message) => message,
        _ => 'Gathering your positions…',
      },
      children: [
        if (state is PortfolioLoaded)
          HairlineList(
            children: [
              for (final position in state.positions)
                PositionRow(position: position),
            ],
          ),
        const SizedBox(height: 22),
        const Text(
          'Everyday things.\nExtraordinary ownership.',
          style: TextStyle(
            fontSize: 23,
            height: 1.15,
            fontWeight: FontWeight.w700,
            letterSpacing: -.8,
            color: AppColors.muted,
          ),
        ),
      ],
    ),
  );
}
