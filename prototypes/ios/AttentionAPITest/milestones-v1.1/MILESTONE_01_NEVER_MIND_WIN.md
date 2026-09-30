# V11-01 — Never Mind feels like a win

**Goal:** make Never Mind feel like the intended choice, not a leftover button. v1 criterion 2 failed: “feels like a button press, not a win.” Copy and host feedback only.

**User-visible change:** shield + Home (and Recap if the same sentence) treat Never Mind as the reward path. XP/streak already count it (+10, Never Mind streak). This milestone makes that visible at the moment of choice and on return to Attention.

**Prerequisite:** V11-00 recorded (PASS or accepted FAIL+fix).

**Agent rule:** implement this milestone only. No closer change. No Continue delay. No lockout. No StoreKit. Honest unit stays `access_window` — do not call Never Mind an “open avoided” unless you can measure opens (you cannot).

## Out of scope

- Layout / type / chrome pass across all tabs → **V11-02**
- New goals, new XP weights, programs
- Changing primary/secondary button order unless the human asks (primary is already Never Mind)

## Context

Today the shield primary is **Never Mind** (blue) and secondary is **Continue**. Home lists “Never Minds (intentional choices)” as a metric. Recap repeats the count. None of that felt like a win on wear.

Keep: Never Mind writes `intentional_choice`, does not bump `continues_today`, stays blocked, `.close`.

## Steps for the agent

1. Shield copy: Never Mind stays the primary action. Add a short win-shaped subtitle or title line that still names the choice (e.g. you chose out / that’s the point). Do not invent open counts. L0–L2 Continue reminders can stay; they must not make Never Mind feel like a consolation.
2. After ingest on Home: a one-line acknowledgment when today’s Never Mind count just rose (timestamped log `ATTN-V11-01`). Ugly is fine: a banner or the Never Mind row calling out the last choice + XP.
3. Recap one-liner: if today has Never Minds, lead with that, not Continues.
4. Do not change `ScoringRules` weights unless a display bug makes +10 invisible.
5. Tag `ATTN-V11-01`.

## Agent exit checks

- [x] Build succeeds (Release, build 4)
- [x] `HardWindowMonitor` / `ReshieldPolicy` / monitor + shield action extensions untouched
- [x] No “opens saved” / session copy
- [x] Never Mind still does not increment Continue level (`recordNeverMind` path unchanged)

## What shipped (2026-09-30, build 4)

- Shield: Never Mind button is green. The subtitle keeps the L0/L1/L2 line and adds “Never Mind is the win: +10 XP. N so far today.” (`InterventionState.neverMindsTodayAll`, max of counter and log).
- Home: a green banner at the top when today’s Never Minds rose since you last tapped **Nice**. It names the last app, the XP, today’s count, and the streak. Logs `ATTN-V11-01 win_shown` / `win_dismissed`.
- Recap: “You chose Never Mind N times today (+XP). …” Leads with Never Mind; says “No Never Minds yet today” when zero.
- XP weights unchanged.

## Physical-device checklist (human)

- [x] Shield Never Mind: still blocked; copy reads as the intended win, not dismiss
- [x] Reopen Attention: Home shows the new Never Mind and it is obvious (not only a number in a list)
- [x] XP / streak still move the same as v1 (+10, streak day)
- [x] Continue path unchanged (extra tap, wall still yanks)
- [x] Recap sentence leads with Never Minds when you had some

## Definition of done

- [x] Human 2026-09-30, TestFlight 0.1 (4): **PASS on all steps.** Still missing: the UI is bland, so the win doesn't land visually yet. That goes to V11-02.

**Next:** [V11-02 — UI pass](./MILESTONE_02_UI_PASS.md)
