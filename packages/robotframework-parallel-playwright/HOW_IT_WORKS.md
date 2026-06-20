# How Parallel Playwright Works — A Plain-English Guide

This document explains, in simple terms, what this tool does, *why* it is clever,
and **whether the idea actually works** (short answer: yes, it does). No coding
knowledge is needed to read this.

---

## 1. The everyday analogy

Imagine you run a shop and you want to test what happens when **10 customers use
your website at the same time** — all searching, adding to cart, checking out at
once.

To do that test, you need 10 "pretend customers" clicking around your site
simultaneously.

There are two ways to create those 10 pretend customers:

### The old way (Pabot) — 10 separate cars
Think of each pretend customer needing their **own car** to drive to your shop.
- 10 customers → **10 whole cars**.
- A car is heavy and expensive: it needs an engine, fuel, a parking space.
- 10 cars = 10 engines running = a huge amount of fuel (computer memory/RAM).

In computer terms, each "car" is a **full web browser** (like a whole separate
Chrome opening up). Ten browsers eats **150–300 MB of memory each** — your
computer groans, fans spin, and it may run out of memory.

### The new way (this tool) — 1 bus with 10 private seats
Instead of 10 cars, we send **one bus** with **10 private, sealed seats** inside.
- Everyone shares **one engine** (one browser).
- Each passenger still has their **own private seat** — their own login, their own
  shopping cart, their own cookies. Passenger 3 can't see passenger 7's stuff.
- A private seat costs almost nothing (**a few MB**) compared to a whole car.

In computer terms, the "bus" is **one single browser**, and each "private seat"
is a **browser context** — an isolated mini-session inside that one browser.

> **The whole point:** 10 pretend customers, but **only one browser engine
> running** instead of ten. Same test, a fraction of the memory.

| | Old way (Pabot) | This tool |
|---|---|---|
| 10 customers at once | 10 full browsers | **1 browser**, 10 private seats |
| Memory cost | Very high | Low |
| Are users isolated? | Yes | **Yes** (still separate carts/logins) |

---

## 2. Why was a special tool even needed?

The testing framework being used (Robot Framework) is like a **single cashier**
who can only serve **one customer at a time**, in a line, one after another. By
itself it *cannot* serve 10 people at once. That's just how it's built.

This tool's trick is: instead of asking the single cashier to magically clone
herself, it moves the actual "shopping work" into a different system (Python's
`asyncio`) that **is** good at juggling many things at once — like one very fast
cashier who takes everyone's order, and while customer 1's payment is processing,
she's already taking customer 2's order, then customer 3's, and so on. Nobody is
truly frozen waiting; the waiting times overlap.

That "juggling many waits at the same time" is the secret. Most of what a browser
test does is **waiting** — waiting for a page to load, waiting for a button to
appear. While one pretend customer waits for a page, the others get to move. That
overlap is where the speed comes from.

---

## 3. What actually happens when you press "go" (step by step)

Here is the whole process, in order, in plain language:

1. **You write your "shopping trips."** Each trip is a short recipe like
   *"open the products page → type a search → click search → check results
   appeared."* Each recipe is called a **scenario**.

2. **You tell the tool: run this trip 10 times, all at once.** (That's the
   `repeat=10` setting — 10 pretend customers doing the same trip.)

3. **The tool opens ONE browser** (the bus starts its single engine).

4. **It creates 10 private seats** inside that one browser (10 isolated contexts —
   one per pretend customer).

5. **All 10 trips start together** and run side by side, their waiting times
   overlapping. Customer 4 isn't stuck behind customer 3.

6. **Each trip's result is recorded** — passed or failed, and how long it took.
   Importantly, if one customer's trip fails, **it does not crash the others** —
   the failure is just noted down.

7. **The browser closes**, and you get a **summary report**: how many passed, how
   many failed, total time, and a confirmation that **only 1 browser was used**.

8. **The test passes or fails** based on whether all the trips succeeded.

---

## 4. The built-in "don't melt the computer" safety controls

Even with one browser, opening 50 private seats at literally the same instant
could still strain a small machine. So the tool has sensible dials:

- **A crowd limit (`max_active_contexts`).** Like saying "only let 8 customers in
  at a time; the rest wait at the door." If you ask for 50, it runs them in
  controlled waves of 8 instead of all 50 at once. Protects memory.

- **Skip the heavy decorations (`block_heavy_resources`).** Images, videos, and
  fonts are the heaviest part of a web page and usually don't matter for testing
  *whether buttons work*. The tool can skip downloading them to save memory. (It
  is careful to **keep the page's styling/CSS**, because without it the page looks
  broken and the test can't find things.)

- **Share one seat instead of private seats (`isolation=page`).** If your test
  genuinely doesn't need each customer to be separate, they can all share one
  seat for the absolute lightest footprint.

- **Watch it happen slowly (`slow_mo_ms`, `hold_seconds`, `headless=False`).** For
  a demo, you can make the browser visible and slow each click down so a human can
  actually watch the 10 customers working.

---

## 5. Is this flow actually possible? — Yes, and here's why it's not a trick

This is a **real, proven, mainstream technique** — not a hack. Three facts back
it up:

1. **Browsers are genuinely built for this.** Playwright (the browser-driving tool
   underneath) officially supports many isolated "contexts" inside one browser.
   This is the documented, intended way to simulate multiple independent users
   cheaply. We are using the tool exactly as designed.

2. **The juggling engine is standard.** Python's `asyncio` running many tasks with
   `asyncio.gather` is a normal, battle-tested way to do many waiting jobs at
   once. Browser automation is mostly waiting, which is the perfect fit.

3. **It is honest about its limits.** The tool doesn't claim to do the impossible.
   It even documents *when you should still use the old way (Pabot)* — for
   example, if you truly need separate operating-system processes, or you're
   testing things that aren't browsers. (See "When to still use Pabot" in the
   README.)

### One honest caveat (so expectations are right)
This is **one browser sharing one set of CPU cores**. It is fantastic at the
*waiting* parts of a test overlapping (page loads, network), which is most of the
work. It is **not** ten separate computers' worth of raw horsepower. So:

- For **"can my site handle many concurrent users / sessions cheaply on one
  machine?"** → this is excellent and exactly the point.
- For a **massive, brutal load-test** (thousands of users hammering for raw
  stress numbers) → you'd still want dedicated load-testing tools or many
  machines. This tool isn't trying to be that, and it says so.

---

## 6. The one-sentence summary

> Instead of opening **ten heavy browsers** to fake ten users (which eats memory),
> this tool opens **one browser** with **ten private, isolated sessions inside it**
> and runs them at the same time — giving you real parallel testing at a fraction
> of the cost. **The approach is standard, supported, and works.**
