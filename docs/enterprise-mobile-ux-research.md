# Tickerless Enterprise Mobile UX Research and Product Direction

Date: 8 September 2026
Scope: Tickerless Flutter mobile app, with emphasis on discovery, Lens, company passports, market content, and the Base Sepolia wallet.

## Executive summary

Tickerless has a differentiated product idea: discover the company behind a real-world object, understand it, and optionally interact with a tokenized test-market representation. The strongest path to an enterprise-quality product is not to add every feature found in a large wallet. It is to make this distinctive path feel reliable, legible, safe, and complete:

1. **Recognize:** the camera communicates what it is doing, returns a credible company match, and offers a graceful correction path.
2. **Understand:** the company passport combines identity, a readable market view, products, and first-party news without dead controls or browser handoffs.
3. **Act safely:** the wallet stays current, exposes network state, protects private balances, and explains a transaction before submission.
4. **Recover:** errors preserve useful state and always provide a clear retry or alternate route.

The competitive review supports five patterns worth adopting now: labeled top-level navigation, progressive disclosure, interactive charts, human-readable transaction review, and visible system state. Those patterns have been implemented in the current pass. More ambitious wallet features—swap aggregation, staking, on/off-ramp, WalletConnect, spending controls, alerts, and watchlists—belong on a staged roadmap and should only appear after their real services, compliance posture, and support model exist.

## Research method and evidence quality

This review used official product pages, official support documentation, and Apple’s Human Interface Guidelines. Marketing claims were treated as evidence of product positioning and exposed capabilities, not independent proof of security. Recommendations were filtered through Tickerless’s current reality: a testnet application with illustrative price series, a company-recognition experience, and a small set of deployed Base Sepolia assets.

No recommendation requires Tickerless to imitate a competitor’s visual styling. The useful layer is behavioral: hierarchy, feedback, safety, continuity, and comprehensibility.

## Competitive patterns

### Solflare: breadth without losing the wallet’s core jobs

Solflare presents mobile as an all-in-one place to trade, stake, collect, send, and receive. Its documentation also emphasizes an in-app browser, hardware-wallet connectivity, notifications, Solana Pay, and rich NFT handling. The useful lesson for Tickerless is not “add many buttons.” It is to keep frequent wallet jobs close together while secondary capabilities live in context-specific destinations. [Solflare product](https://www.solflare.com/product/), [Solflare documentation](https://docs.solflare.com/solflare)

For Tickerless, Send and Receive are the appropriate primary wallet actions today. A duplicate Deposit action and a Swap control that only reports “unavailable” weaken trust; both should stay out of the primary row until they represent distinct, working flows. A future swap must remain behind a capability flag until a real quote, review, slippage, and execution flow exists.

### Phantom: make safety understandable before asking for consent

Phantom describes human-readable transaction previews, real-time warnings, spam hiding, and malicious-domain controls as core user protections. This is important because wallet security cannot rely on a user reading hashes or raw instructions. The interaction must translate a pending action into asset, amount, recipient, network, likely fee behavior, and risk context before confirmation. [Phantom security](https://phantom.com/learn/blog/security-at-phantom), [Phantom getting started](https://phantom.com/get-started)

Tickerless previously labeled its submit action “Review and send” but submitted immediately. The current implementation now inserts a real review stage. Longer term, the same pattern should cover purchases, sales, approvals, and any future contract interaction.

Phantom also exposes interactive token charts. This supports a familiar mobile-market behavior: users drag across a chart to inspect values rather than reading a decorative line. [Charts in Phantom](https://phantom.com/learn/blog/charts-in-phantom)

### Fuse: progressive security and recovery

Fuse foregrounds biometrics, two-factor controls, recovery keys, spending limits, on/off-ramp, swaps, staking, and card-related flows. Its framing is progressive: users can start simply and add stronger controls as their needs increase. [What is Fuse](https://fusewallet.com/support/what-is-fuse), [Getting started with Fuse](https://fusewallet.com/support/getting-started-with-fuse)

The right Tickerless translation is a security center with clearly separated layers:

- device access: Face ID or Touch ID gate;
- recovery: understandable backup status and verified recovery flow;
- transaction policy: confirmations, optional limits, and trusted recipients;
- session visibility: last activity and a way to revoke sessions;
- education: testnet/mainnet and asset-status explanations placed at the moment of action.

None should be represented as active until it is enforced end to end. A decorative “2FA enabled” label without server and recovery semantics would create false assurance.

### Jupiter Mobile: portfolio and execution as a connected system

Jupiter’s official documentation brings mobile, portfolio tracking, asset management, and rewards into the same product family. Its broader product is known for routed execution, but the relevant Tickerless lesson is the connection between seeing a position and acting on it: a portfolio row should lead to understandable details, history, and a contextual action—not a disconnected feature grid. [Jupiter documentation](https://docs.jup.ag/)

Tickerless already follows this direction by making assets tappable and routing owned company positions back to their passports. The next step is to add confirmed/pending/failed transaction states and a dedicated transaction receipt with explorer access.

### Apple Stocks: glanceable lists, progressive chart detail, and contextual news

Apple Stocks combines a symbol list, mini performance charts, price/change values, watchlists, interactive charts, metrics, and related news. The hierarchy is effective: the list answers “what changed,” while a detail page answers “why” and “over what period.” [Use Stocks on iPhone](https://support.apple.com/guide/iphone/check-stocks-iph1ac0b1bc/26/ios/26)

Apple’s chart guidance recommends a concise summary, consistent hierarchy, optional interaction for extra detail, large hit targets, and accessible alternatives. Its charting guidance similarly favors a simple initial view with progressive detail. [Apple HIG: Charts](https://developer.apple.com/design/human-interface-guidelines/charts), [Apple HIG: Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data?changes=l_1__1_8&language=objc)

Tickerless’s company passport now supports drag/tap inspection while retaining a readable start/end summary for assistive technology. The next data-layer milestone is to replace illustrative series with timestamped market data and expose the timestamp beneath the selected value.

## Tickerless UX audit

### Navigation

The former bottom bar used recognizable icons but did not show labels. That increases interpretation cost and makes accessibility metadata carry work that should also be visible. Apple recommends tab bars for top-level navigation, persistent access, and concise labels; actions belong in contextual toolbars or the content itself. [Apple HIG: Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars?changes=l_1__4&language=objc), [Apple HIG: Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars?changes=la)

Implemented response:

- Discover, World, and Wallet now show persistent labels.
- The selected destination has a subtle visual container, not color alone.
- Re-tapping the active tab still returns its navigation branch to the root.
- Lens-specific Link and Search actions remain removed from the bottom of the camera view; Lens stays focused on capture and recognition.

### Discover and Lens

The oversized first NVIDIA card created false priority and reduced content reach. The revised layout constrains the feature card and makes the remaining discovery content a normal continuous scroll. This respects the primary mobile gesture and avoids a scroll-inside-scroll trap.

Lens now prefers the rear camera, forwards native Vision results safely to Flutter on the main thread, considers a broader set of candidates, and includes Microsoft in the matching catalog. The remaining product risk is confidence communication. A future result screen should distinguish:

- high confidence: proceed with a short undo/correct option;
- medium confidence: show two or three company candidates;
- low confidence: explain what Lens saw and offer Search or another scan.

This is preferable to silently forcing a weak match.

### Wallet state and privacy

The wallet previously refreshed by replacing its future, which could temporarily blank the on-chain values during every polling cycle. The enterprise pattern is continuity: retain the last confirmed data, show background progress separately, and surface stale/error state without destroying useful context. Apple’s loading guidance recommends showing content early and loading in the background instead of presenting an empty interface. [Apple HIG: Loading](https://developer.apple.com/design/human-interface-guidelines/loading?changes=_4_8)

Implemented response:

- Poll Base Sepolia every 12 seconds while the wallet is mounted.
- Refresh immediately after app resume and after an in-app send.
- Preserve the last successful snapshot during refresh or a temporary failure.
- Expose Connecting, Updating, Live, Offline, and Retry states.
- Keep pull-to-refresh and provide a compact explicit retry target.
- Add balance privacy mode covering the total, performance, and asset amounts.

Apple recommends requesting only needed data access, using system protections, and giving people transparency and control over sensitive information. Balance privacy is a small but meaningful expression of that principle in shoulder-surfing contexts. [Apple HIG: Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy?changes=_10_7)

### Transaction comprehension

Implemented response:

- Validate recipient and available balance before opening review.
- Show asset, exact amount, full selectable recipient, network, and fee behavior.
- Make testnet status and irreversibility explicit.
- Require a separate “Confirm and send” action.
- Trigger tactile feedback at the moment of submission.
- Refresh the wallet when execution completes.

Next, the backend should return a transaction identifier immediately so the app can show a pending row, confirm asynchronously, and link to an explorer receipt.

### Company passport and news

The passport had two visually active but inert app-bar controls. Dead controls are more damaging than missing controls because they break the user’s mental model of cause and effect.

Implemented response:

- Share now copies a concise company snapshot.
- More now opens a disclosure sheet covering demo market data, test-token availability, and the discovery source.
- News rows on both World and Passport open in an in-app browser and preserve navigation back to Tickerless.
- Chart values can be inspected by touch.
- Light-theme tab colors and the pinned action bar now derive from the active color scheme.

## Prioritized roadmap

### P0 — release confidence

These items should gate any move beyond a small TestFlight cohort:

1. **Transaction state model:** pending, confirmed, and failed rows with hash, block explorer, timestamps, and retry guidance.
2. **Recognition telemetry with privacy controls:** capture label candidates, confidence, selected match, correction, latency, and device model without retaining camera images by default.
3. **Error taxonomy:** distinguish no connection, RPC timeout, insufficient gas, rejected signature, unavailable asset, and server failure.
4. **Accessibility pass:** VoiceOver order, dynamic type at the largest sizes, contrast, motion reduction, and 44-point interactive targets.
5. **TestFlight observability:** crash reporting, non-sensitive performance traces, and release health by build.
6. **Source/data disclosures:** every demo, delayed, first-party, or live datum must be labeled accurately.

### P1 — retention and daily usefulness

1. **Watchlists:** let users follow companies found by Lens or Search, reorder them, and see compact change indicators.
2. **Alerts:** company news, recognition follow-ups, inbound wallet transfers, and transaction confirmations. Notifications should be granular and off by default where appropriate.
3. **Unified activity:** purchases, sales, sends, receives, and Lens discoveries in a chronological timeline with filters.
4. **Real market data:** timestamped series, market status, source attribution, and delayed/live labeling.
5. **Saved recipients:** user-named addresses with explicit verification, recent-use cues, and protections against clipboard replacement.
6. **Lens correction:** candidate chooser and “not this company” feedback that improves matching quality.

### P2 — expanded financial capability

Only add these with production-grade integrations and review screens:

- swap aggregation with quotes, slippage, price impact, route, and minimum received;
- WalletConnect or an equivalent reviewed dApp connection model;
- on/off-ramp with regional eligibility and compliance handling;
- staking or earn products with clear protocol, lockup, yield, and risk disclosures;
- spending policies, trusted recipients, or configurable limits;
- hardware-wallet support.

The feature flag should control both visibility and routing. An unavailable action should not occupy permanent prime space.

## Recommended end-to-end experience

### Object to company

1. Open Lens from Discover.
2. Explain camera use before the system permission prompt if context is needed.
3. Show a stable framing guide and short capture instruction.
4. Preserve the camera preview while analyzing; use a compact progress state.
5. On strong match, show company, recognized object, and confidence language.
6. On ambiguity, show candidates; never pretend certainty.
7. Open the passport with a visible “Identified from Lens” source.
8. Allow correction without restarting the entire flow.

### Company to informed action

1. Passport opens with company identity and readable current context.
2. Chart has a summary first and touch detail second.
3. About, Products, and News change actual content.
4. News stays inside the app.
5. Ownership disclosure identifies Base Sepolia and test-token status.
6. Purchase or sale shows a human-readable review.
7. Completion leads to a receipt and updated wallet state.

### Wallet transfer

1. Wallet retains the last successful balance while syncing.
2. User can hide all sensitive values with one control.
3. Send form shows available asset balance and validates locally.
4. Review translates the pending action into plain language.
5. Submit produces haptic acknowledgment and a pending state.
6. Confirmation updates balance and activity without manual refresh.
7. Failure preserves entered data and gives actionable recovery guidance.

## Measurement plan

Enterprise polish should be measured as reliability and comprehension, not visual novelty. Recommended metrics:

- Lens successful-match rate, correction rate, time to result, and abandonment by stage;
- passport-to-news open rate and in-app reader return rate;
- wallet snapshot success rate and age of the last successful balance;
- transfer validation failure by reason, review cancellation, submission success, and confirmation latency;
- crash-free sessions and screen render latency by build;
- accessibility test coverage and dynamic-type overflow defects;
- support contacts per 1,000 transactions, categorized by user-understood failure reason.

Telemetry must exclude private keys, seed phrases, raw camera images, and full wallet addresses unless strictly necessary and appropriately protected.

## Release acceptance checklist

- All three top-level destinations are labeled, reachable, and preserve their stack.
- Discover scrolls as one continuous surface with no oversized feature card.
- Lens uses the rear camera and handles permission denial, retry, ambiguity, and supported-company matching.
- Wallet balances update on polling, resume, incoming transfer, and in-app transaction completion.
- Background refresh never blanks a previously confirmed balance.
- Balance privacy hides total, performance, and row values.
- Every transaction has a separate review and confirmation step.
- News opens inside Tickerless and returns to the prior screen.
- Company and token representations use real artwork where available and branded monograms as fallback.
- Light and dark themes maintain readable contrast.
- Demo market data and testnet assets are explicitly disclosed.
- VoiceOver, dynamic type, keyboard handling, offline state, and smallest supported screen size pass QA.

## Sources

- Apple, [Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars?changes=l_1__4&language=objc)
- Apple, [Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars?changes=la)
- Apple, [Charts](https://developer.apple.com/design/human-interface-guidelines/charts)
- Apple, [Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data?changes=l_1__1_8&language=objc)
- Apple, [Loading](https://developer.apple.com/design/human-interface-guidelines/loading?changes=_4_8)
- Apple, [Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy?changes=_10_7)
- Apple Support, [Check stocks on iPhone](https://support.apple.com/guide/iphone/check-stocks-iph1ac0b1bc/26/ios/26)
- Fuse, [What is Fuse?](https://fusewallet.com/support/what-is-fuse)
- Fuse, [Getting started with Fuse](https://fusewallet.com/support/getting-started-with-fuse)
- Fuse, [Wallet Suite](https://www.fuse.io/wallet-suite)
- Jupiter, [Jupiter documentation](https://docs.jup.ag/)
- Phantom, [Security at Phantom](https://phantom.com/learn/blog/security-at-phantom)
- Phantom, [Get started](https://phantom.com/get-started)
- Phantom, [Charts in Phantom](https://phantom.com/learn/blog/charts-in-phantom)
- Solflare, [Product](https://www.solflare.com/product/)
- Solflare, [Documentation](https://docs.solflare.com/solflare)
- Solflare, [Help Center](https://help.solflare.com/en/)
