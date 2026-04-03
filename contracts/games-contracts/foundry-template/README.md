Periodic checkpoint accuracy (Cloudflare vs Chainlink)

`Counter` tracks how early or late each periodic call was versus a fixed interval (default 5 minutes). Use it to evaluate Cloudflare Workers vs Chainlink Automation.

Contract

- File: `src/Counter.sol`
- Constructor: `Counter(uint256 intervalSeconds)`; pass 0 to default to 300s
- Call `checkpoint()` roughly every `interval` seconds
- Inspect `records(i)` or `latestRecord()` to analyze accuracy

Run tests (requires Foundry)

```bash
forge test -vvv
```

Cloudflare Worker

- See `cloudflare-worker/`
- Set ENV: RPC_URL, PRIVATE_KEY, CONTRACT_ADDRESS, CHAIN_ID
- Cron: `*/5 * * * *`

Interpretation

- offsetSeconds < 0: early by |offsetSeconds|
- offsetSeconds > 0: late by offsetSeconds
- Compare distributions across many intervals to decide if Workers suffice or if Automation is justified.
