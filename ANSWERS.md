# Written section

Student number: ZNDNDU007

Answer all five questions. **Maximum 120 words each.**

Full marks need specifics from your own work: your assigned values, your deployed addresses, your
numbers, your error messages, your range.

---

## Question 1 (5 marks)

Your sheet gave you two long starting price numbers rather than one. Explain why there are two,
state which of your two tokens ended up as `currency0` and how you knew, and say what would have
gone wrong if your code in TODO 2.1 had picked the other number.

**Answer:**

A v4 pool sorts its two currencies by address, and I could not choose which of mine won, so the
sheet had to cover both outcomes. Token A (BAOB, `0x5e17b1…Eff5`) sorts below token B
(HIVE, `0xe2899b…157A`), so `alphaIsCurrency0()` returned true and TODO 2.1 selected
`200433158700038344949131041255`. Squared over 2^96 that is exactly 6.4, HIVE per BAOB, which is
the correct quote when BAOB is currency0. `openPool` confirmed it, returning tick 18563.

Had I returned `31317681046880991398301725196`, the pool would have opened at 0.15625 instead,
tick −18564: the price inverted, wrong by 40.96×. My range [14600, 22600] would then sit far above
the live tick and `addLiquidity` would revert with "your range does not contain the live tick".

---

## Question 2 (5 marks)

You committed a predicted output before swapping. State the number you predicted, how you arrived
at it, and the output you actually received. Provide a short explanation of why the two numbers were different (if they were). (If they were the same, explain why you were able to predict it so accurately.)

**Answer:**

I predicted `6396800000000000000`, that is 6.3968 HIVE. My `startingSqrtPriceX96` squared over 2^96
is exactly 6.4 HIVE per BAOB, and the 500 fee tier is 500/1,000,000 = 0.05%, taken off the input
before it reaches the curve. So 1 BAOB × 0.9995 × 6.4 = 6.3968.

I actually received `6395182941401903119`, which is 1617058598096881 less, a shortfall of 0.025%.

The gap is price impact. My prediction used the spot rate, but the swap walks along the constant
product curve: selling currency0 dropped sqrtPriceX96 from 200433158700038344949131041255 to
200382490840699360848466989459, so each later fraction of my input traded a little below 6.4. The
swap earns the average rate across that move, not the rate it started at.

---

## Question 3 (5 marks)

Quote the exact error message you hit on your first failed attempt at adding liquidity, and explain
the cause in terms of your own tick spacing and your own live tick. If your first attempt worked,
say so, then deliberately trigger one of the checks you wrote in TODO 3.1 or 3.2, quote the message
it gave, and explain what caused it.

**Answer:**

My first attempt worked: `addLiquidity(14600, 22600, 10000000000000000000000)` succeeded and
returned amount0 −722332004209315486817 and amount1 −4548172544717148120088.

I then deliberately tripped TODO 3.1 by calling `addLiquidity(14601, 22600, ...)`. It reverted with
"tickLower is not a multiple of the tick spacing".

My tick spacing is 200, so the only ticks that may hold liquidity are multiples of 200: …, 14400,
14600, 14800, …. The check is `tickLower % TICK_SPACING == 0`, and 14601 % 200 = 1, so it failed.
Without my check the protocol itself would still have rejected it, but with a far less readable
error. The live tick, 18563, was never the problem here.

---

## Question 4 (5 marks)

State the tick range you chose and why. If you had chosen a range entirely above the live tick,
explain what your Task3Liquidity contract would have done with TODO 3.2 completed correctly.
Then suppose that range-containment check were removed, with all other inputs valid: name which
of your two tokens Uniswap would have taken, which it would have left alone, and why.

**Answer:**

I used [14600, 22600]. Both are multiples of my spacing of 200 and they straddle the live tick of
18563, so my liquidity is active and earns fees. The 8000-tick width gives roughly ±50% of price
room before the position goes one-sided.

A range entirely above 18563 would hit TODO 3.2, `tickLower <= liveTick && liveTick < tickUpper`,
and revert with "your range does not contain the live tick". Nothing would move.

Remove that check and the call would succeed, but Uniswap would take only BAOB, my currency0, and
leave HIVE untouched. A range above the current price sits entirely on the currency0 side of the
curve, so currency1 is not needed yet.

---

## Question 5 (5 marks)

Both your tokens use 18 decimals. Suppose token A had used 6 instead and token B still used 18, with the same real world
price. State what would change about the starting price number you passed in, and state what in
your pool key would be completely unaffected. Explain why the pool itself neither knows nor cares
about decimals.

**Answer:**

`sqrtPriceX96` encodes raw units, not tokens. With BAOB at 6 decimals, 1 BAOB is 10^6 raw and 6.4
HIVE is 6.4×10^18 raw, so the ratio becomes 6.4×10^12 rather than 6.4. The square root scales by
10^6, so I would pass `200433158700038344949131041255000000` instead, and the pool would open near
tick 294887 rather than 18563.

My pool key is completely unaffected: both currency addresses, fee 500, tickSpacing 200 and
hooks `address(0)`. None of its five fields encodes decimals, so the poolId is unchanged.

`decimals` is ERC20 display metadata for humans. PoolManager only ever moves integer raw balances
and never reads it, so the scaling has to be baked into the price instead.
