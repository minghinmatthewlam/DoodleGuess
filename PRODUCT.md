# DoodleGuess - Product Spec

## One-liner

Draw for your partner; their drawing appears on your home screen widget.

## Core Value Proposition

**Glance at phone → see partner's drawing → feel connected.**

The widget IS the product. Users don't open the app to "use an app" - they want to see something from someone they love on their home screen.

---

## Key Design Principles

### 1. Widget-First Design

The widget's only job: **display their drawing prominently**.

| Widget MUST show | Widget must NOT show |
|------------------|---------------------|
| Partner's actual drawing (big, visible) | "Open app to see content" |
| Fresh/recent content | Loading states, spinners |
| Their personality/style | "Waiting for partner..." |
| Something always (yesterday's if needed) | Empty states, error messages |

**Rule:** Widget always displays a drawing. Never empty, never waiting.

### 2. Simplicity Over Features

- No streaks or gamification (noteit's main criticism)
- No complex onboarding - pair in under 30 seconds
- One core action: draw and send
- Daily ritual, not a time sink

### 3. Async by Design

- No need to be online at the same time
- Draw whenever, partner sees it when they glance at phone
- Works on poor network (offline queueing)

---

## MVP Phases

Each phase is independently shippable and validates assumptions before investing in the next.

```
Phase 1          Phase 2              Phase 3
────────         ──────────           ──────────
Free Draw   →    Daily Prompt    →    Same Word Compare
(no rules)       (suggested word)     (reveal together)
```

---

## Phase 1: Free Draw (Core MVP)

### What It Does
- Draw anything → appears on partner's widget
- No prompts, no game, just passing drawings back and forth
- This is what noteit does - proven model

### User Flow

```
FIRST TIME:
1. Open app → Welcome screen
2. "Create Pair" → get invite code (e.g., "ABC123")
3. Share code with partner (text, airdrop, etc.)
4. Partner opens app → "Join Pair" → enters code
5. Both connected → canvas ready

DAILY USE:
1. Open app → drawing canvas
2. Draw something
3. Tap send
4. Partner's widget updates with your drawing
5. Partner gets push notification
6. Partner taps widget → sees drawing full screen
7. Partner draws back → cycle repeats
```

### Phase 1 Verification Checklist

**Pairing:**
- [ ] User A can create a pair and gets a 6-character code
- [ ] User B can join using that code
- [ ] Both users see each other as "connected"
- [ ] Pairing persists across app restarts
- [ ] User can disconnect and re-pair with someone else

**Drawing:**
- [ ] Canvas loads and is responsive
- [ ] Can draw with finger (and Apple Pencil if available)
- [ ] Can change colors (at least 5-6 basic colors)
- [ ] Can erase
- [ ] Can undo last stroke
- [ ] Can clear entire canvas
- [ ] Drawing looks good (not pixelated/blurry)

**Sending:**
- [ ] Tap send → drawing uploads
- [ ] Success confirmation (subtle, not intrusive)
- [ ] Works on wifi and cellular
- [ ] Handles offline gracefully (queue and retry)

**Receiving:**
- [ ] Partner's widget updates within ~30 seconds
- [ ] Push notification arrives on partner's phone
- [ ] Notification tap opens the app
- [ ] Drawing displays correctly in app

**Widget:**
- [ ] Widget can be added to home screen
- [ ] Widget shows partner's latest drawing
- [ ] Widget updates when new drawing arrives
- [ ] Widget tap opens the app
- [ ] Widget shows placeholder if no drawings yet (never empty)

**History:**
- [ ] Can view list of past drawings
- [ ] Shows both sent and received
- [ ] Sorted by date (newest first)

**Edge Cases:**
- [ ] App works after phone restart
- [ ] Widget works after phone restart
- [ ] Handles poor network gracefully
- [ ] Two users can't pair with same code twice

---

## Phase 2: Daily Prompts

**Only build after Phase 1 is fully verified.**

### What Changes
- App shows "Today's word: ____" banner above canvas
- Prompt is OPTIONAL - user can still draw anything
- Same word for all users globally each day
- Widget behavior unchanged (just shows drawing)

### Phase 2 Verification Checklist

- [ ] App shows today's word on canvas screen
- [ ] Word changes at midnight (user's timezone or UTC)
- [ ] Same word shows for both partners
- [ ] User can ignore prompt and draw anything
- [ ] Word is appropriate (no offensive content)

**Engagement (measure after 1-2 weeks):**
- [ ] Do users draw more often with prompts?
- [ ] Do users follow the prompt or ignore it?
- [ ] Any user feedback on prompt quality?

---

## Phase 3: Same Word Comparison

**Only build if Phase 2 shows users engage with prompts.**

### What Changes
- Both partners draw the same word
- After BOTH submit, app shows side-by-side comparison
- Can react to each other's interpretation (emoji, drawn response)
- Creates "how did you see it?" moments

### Game Mode Options

| Mode | Description | Recommendation |
|------|-------------|----------------|
| One drawer, alternating | Today you draw, tomorrow you guess | Simple but less content |
| Both draw different words | Each guesses the other's | More effort, can feel like work |
| **Both draw same word** | Compare interpretations side-by-side | **Recommended** - fun, shareable, no winner/loser |

### Phase 3 Verification Checklist

- [ ] App knows when both users have drawn today's word
- [ ] Comparison view shows both drawings side-by-side
- [ ] Clear indication of whose drawing is whose
- [ ] Can react with emoji or drawn response
- [ ] Comparison is shareable (export as image)
- [ ] Widget still shows latest drawing (not comparison state)

---

## Competitive Landscape

### noteit (Primary Reference)
- **App Store:** https://apps.apple.com/us/app/noteit-bff-widget/id1570369625
- **What it does:** Send doodles to friends via widgets
- **Strengths:** Simple, personal, widget-first
- **Weaknesses:** Became cluttered with streak mechanics and gamification
- **Our angle:** Phase 1 = cleaner noteit. Phases 2-3 = differentiation.

### Locket (Inspiration)
- Photo-sharing widget app
- Started as founder's gift to girlfriend
- 35M+ signups, Apple App Store Award winner
- Proves: simple widget apps can be massive
- Origin story: https://www.fastcompany.com/90818702/how-locket-a-widget-built-by-a-guy-as-a-gift-to-his-girlfriend-became-an-apple-app-store-award-winner

### Draw Something (Cautionary Tale)
- Was huge (35M downloads in 6 weeks), now feels dated
- Async 1v1 drawing guessing game
- No widget presence
- Shows the space exists, but needs modern widget-first approach

### Skribbl-Style Games
- Skribbl.io, Gartic.io - web-based, real-time
- No native iOS app, no widget
- **Gap:** None are widget-first, daily ritual, or async comparison focused

---

## Target Users

### Primary: Couples
- Long-distance or living together
- Want small daily touchpoints
- Value personal/creative connection over text

### Secondary: Close Friends
- Best friends, siblings
- Playful daily interaction
- Inside jokes form over time

### Tertiary: Family
- Parents/grandparents with kids
- Simple enough for all ages
- Seeing grandkid's drawing on home screen

---

## Monetization (Future)

Not for MVP, but potential directions:

| Feature | Model |
|---------|-------|
| Premium word packs (spicy, nostalgic, custom) | One-time or subscription |
| Gallery export (year of drawings as book) | One-time |
| Multiple partners/friends | Subscription |
| Themes (paper styles, pen styles) | One-time |
| Group games (3+ people) | Subscription tier |

---

## Success Metrics

### Phase 1 Launch
- Two real users can pair and exchange 10+ drawings over a week
- Widget updates reliably on both phones
- Push notifications arrive reliably
- No crashes or data loss
- DAU/MAU ratio > 50% (daily ritual achieved)

### Growth Indicators
- Organic sharing (screenshots of drawings on social)
- Word of mouth (users inviting partners/friends)
- App Store reviews mentioning widget experience

---

## What We're NOT Building

- ❌ Social network / public feed
- ❌ Streaks or gamification
- ❌ Complex drawing tools (layers, shapes, etc.)
- ❌ Text messaging / chat
- ❌ Photo sharing (that's Locket's space)
- ❌ Android (iOS first, validate before expanding)

---

## References

- [Superwall: How to Ideate a Viral App](https://superwall.com/blog/how-to-ideate-a-viral-app-in-2025)
- [Locket Origin Story](https://www.fastcompany.com/90818702/how-locket-a-widget-built-by-a-guy-as-a-gift-to-his-girlfriend-became-an-apple-app-store-award-winner)
- [Shopify: Lessons Building iOS Widgets](https://shopify.engineering/lessons-building-ios-widgets)
- [iOS Tech Stack for Indie Apps 2024](https://medium.com/arcush-tech/the-ios-technology-stack-you-need-to-create-an-indie-app-in-2024-6bd66d82b880)
