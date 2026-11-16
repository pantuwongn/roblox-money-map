# MoneyMap — Roblox map with every way to earn money

A complete Roblox experience generated from code. It has these zones:

| Zone | What it is | How it earns |
|---|---|---|
| **Hub** (spawn) | Spawn area, signs, daily chest | Daily reward brings players back (Engagement Payouts) |
| **Obby** (east, in the sky) | 12 stages: jumps, beam, lava, disappearing platforms, spinners. Progress saves | **Skip Stage** product, finish reward |
| **Coin Field** (south) | Coins to collect | Makes **2x Coins** and coin packs worth buying |
| **VIP Room** (west) | Gold room with rare 5-coin diamonds | **VIP** Game Pass |
| **Shop** (north) | Walk-up pads with signs showing real prices | All passes and products |
| **Shop menu** (button on screen) | Same items, plus a Premium upsell | All passes and products, Roblox Premium |

### Money features included
- **Game Passes:** VIP, 2x Coins, Speed Boost, Super Jump
- **Developer Products:** 100 / 500 / 2500 Coins, Skip Stage, **Coin Rain** (everyone in the server sees who bought it, which is free advertising)
- **Premium bonus:** +25% coins for Premium players. This raises your **Engagement-Based Payouts**.
- **Safe purchases:** `ProcessReceipt` saves the receipt before confirming the purchase, so players never lose a purchase and never get it twice.
- **DataStore saving:** coins, obby stage and the daily timer are saved.

## Setup

### Option A: Rojo (recommended)
1. Install [Rojo](https://rojo.space) (VS Code extension + Studio plugin).
2. Run `rojo serve` in this folder, then click **Connect** in the Studio Rojo plugin.

### Option B: Copy by hand (no tools)
Create these in Studio and paste each file's code:

| Studio location | Type | File |
|---|---|---|
| ReplicatedStorage > Folder **Shared** | ModuleScript `Config` | `src/shared/Config.lua` |
| ReplicatedStorage > Shared | ModuleScript `Perks` | `src/shared/Perks.lua` |
| ServerScriptService > Folder **Server** | **Script** `Main` | `src/server/Main.server.lua` |
| ServerScriptService > Server | ModuleScripts `Util`, `Remotes`, `DataService`, `MapBuilder`, `ObbyService`, `CoinService`, `MonetizationService`, `RewardService` | `src/server/<Name>.lua` |
| StarterPlayer > StarterPlayerScripts | **LocalScript** `ClientMain` | `src/client/ClientMain.client.lua` |

Names must match exactly.

### Then
1. **Publish** the place (File > Publish to Roblox).
2. Game Settings > Security: turn on **Enable Studio Access to API Services** (needed for saving).
3. Press **Play**. The map builds itself. In Studio you get every Game Pass automatically so you can test (`Config.GiveAllPassesInStudio`).

## Turning on real purchases
1. Go to https://create.roblox.com > your experience > **Monetization**:
   - **Passes:** create VIP, 2x Coins, Speed Boost, Super Jump.
   - **Developer Products:** create 100 Coins, 500 Coins, 2500 Coins, Skip Stage, Coin Rain.
2. Copy each ID into `src/shared/Config.lua` (replace `Id = 0`).
3. Set prices on the dashboard. Signs and the shop menu show the real prices automatically.

## Other income (settings only, no code)
- **Private Servers:** Creator Dashboard > Monetization > Private Servers, set a monthly price.
- **Paid Access:** charge Robux to join (only worth it once you have an audience).
- **Immersive / Rewarded Ads:** Creator Dashboard > Monetization > Ads (subject to eligibility).
- **Engagement-Based Payouts:** automatic, paid for Premium players' play time.
- **DevEx:** cash out earned Robux once you have 30,000+ and are 13+ and verified.

## Customizing
- All prices, rewards, speeds and coin values are in `Config.lua`.
- `Config.Obby.Stages` changes the obby length.
- The `Map` folder is rebuilt every time the server starts. Put hand-built decorations in a different Workspace folder.

## Ideas to earn more next
- Pets / eggs (a very strong earner in simulators)
- Rebirths with a 2x Rebirth pass
- A coin leaderboard (OrderedDataStore)
- Group join reward
- Limited-time events (holiday coins)
