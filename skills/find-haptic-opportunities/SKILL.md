---
name: find-haptic-opportunities
description: Audit a mobile interface for missing tactile feedback and propose precise haptic recipes with code evidence. Use for a haptics opportunities pass, asking which interactions should vibrate or tick, or deciding where haptic feedback belongs. Read-only; it produces recommendations, not implementation, unless the user also requests implementation.
---

# Find haptic opportunities

Find moments where touch feedback clarifies a user's action. Prefer a short list of useful ticks over vibration on every press. Judge haptics on their own merits: an animation is not evidence that a haptic is needed, because motion explains a change to the eye while a haptic confirms an action to the hand.

## Establish the baseline

Read the project's haptic wrapper and its platform variants before searching callers. Identify the available semantic effects, native controls, toast/result feedback, press debouncing, and navigation guards. Trace each candidate through its callers and callees. A missing import at the button does not prove a missing haptic.

If there is no wrapper, find direct platform calls instead: `expo-haptics`, `react-native-haptic-feedback`, `UIFeedbackGenerator` subclasses, SwiftUI `.sensoryFeedback`, `performHapticFeedback`/`HapticFeedbackConstants`, Compose `LocalHapticFeedback`, or Flutter `HapticFeedback`. If the app emits no haptics at all, say so, recommend the platform API or an already-installed library, and flag any new dependency as the user's decision.

Search for selection changes, explicit navigation controls, sheet openers, long-press recognition, gesture detents, commit/retry handlers, and visible write results. Also inspect typing, scrolling, loading, and ordinary browsing so the report explains what should stay quiet. Use the project's device tooling when it helps inspect behavior. Never mutate backend or account data just to reach a result state; the audit is read-only.

## Gate each candidate

Ask these questions in order. Record the answers briefly in the recommendation.

1. **Meaning.** What does the user learn through touch? Accept a meaningful selection, recognized action, committed operation, gesture threshold, or visible result. Reject decoration and passive data changes. A deliberate contextual navigation control can qualify; that does not justify feedback on every card or back action.
2. **Frequency.** How often is it used? Frequent discrete selections can earn a light tick. Continuous scrolling, typing, and loading stay quiet. Animation frequency cutoffs do not transfer: haptics cost no visual time, but repeated vibration fatigues the hand.
3. **Ownership.** Is feedback already provided by a wrapper, caller, native control, toast, or gesture-settle callback? Choose one owner per event. If native behavior is uncertain, mark the candidate as requiring hardware verification rather than assuming silence.
4. **Timing and truth.** Which accepted event should emit it? Fire selection on an actual value change, commit on an accepted submit, and success/error only on the known visible outcome. Disabled controls, unchanged selections, rejected navigation, cancelled gestures, and automatic advances do not earn a new pulse. A commit pulse and a later result pulse describe separate events; two result pulses do not.
5. **Support and comfort.** Can the existing platform wrapper deliver a subtle effect without blocking the action? Keep visual and accessible feedback sufficient when haptics are unavailable or disabled. Respect haptic preferences and platform settings. Reduced motion is not itself a haptics preference. Never add a web vibration fallback or override system settings as part of an opportunities pass.

Reject a candidate when it fails a gate. Return fewer recommendations if only a few survive.

## Specify the recipe

Reuse the app's semantic vocabulary. For example, when these methods exist:

| Meaning | Recipe |
| --- | --- |
| Changed selection or accepted contextual control | One `haptics.selection()` tick |
| Accepted operation that commits a change | One `haptics.confirm()` at submit |
| Known success or failure | Existing success/error feedback at the outcome owner |

Verify actual mappings in the repository. Do not invent amplitude, duration, or waveform values for platform presets. Do not introduce a new dependency or expand the vocabulary merely to distinguish two buttons.

Name the handler and trigger, count, existing preset, duplicate-prevention rule, platform coverage, and remaining uncertainty. A tap and swipe that reach the same destination must not both pulse for one interaction. Keep automatic programmatic changes quiet unless they are the visible result already being acknowledged.

Never schedule haptics with a timer to imitate an animation's duration. Use the actual gesture threshold, accepted press, state change, or result event. Do not emit during render or subscribe to changing UI state just to make it buzz.

## Report

For a whole app, return at most seven recommendations ordered by user value. For one screen, return fewer. Include:

- An existing-feedback summary, including who owns result feedback.
- A table with location and line, current behavior, purpose and estimated frequency, exact recipe and owner, and platform or verification caveats.
- Two to five deliberately rejected candidates with the gate that rejected each.
- The first change to implement and a small verification checklist.

When the user supplies a candidate, assess it explicitly even if it is already covered or rejected. Save the report where the user asks or where the repository keeps similar docs; otherwise return it in the reply. An audit alone does not authorize implementing the recommendations.

Distinguish source inspection, simulator interaction, and physical-device evaluation. A screenshot cannot establish tactile quality. A simulator can verify navigation and event routing, but cannot prove how a pulse feels on an iPhone or Android actuator. Never report hardware feel as verified without that evidence.

## Reference guidance

Use platform guidance to settle disputed semantics or support questions, not to replace the app's existing vocabulary:

- [Apple: Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics)
- [Android: Haptics design principles](https://developer.android.com/develop/ui/views/haptics/haptics-principles)
