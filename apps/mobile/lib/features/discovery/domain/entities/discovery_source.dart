/// How a company was discovered. Carried through to the purchase so a position
/// can say what led to it.
enum DiscoverySource {
  lens('Lens'),
  link('Link'),
  search('Search'),
  trending('Discover');

  const DiscoverySource(this.label);
  final String label;

  /// `"iPhone · Lens"` — the provenance line shown on positions and receipts.
  String describe(String context) => '$context · $label';
}
