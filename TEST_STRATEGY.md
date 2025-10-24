##  Why did you choose your application?
Basically it was the one I've liked the most from the examples
you've provided.
##  What are the main risks for this application?
- Players abandoning games - No timeout or penalty if someone refuses to reveal after losing.
- Weak nonces - Predictable nonces could be brute-forced before reveal.
- No game cleanup - Abandoned games stay in storage forever.
- Access control - Anyone can create a game for anyone else without consent.

##  How did you structure your tests and why? What are you testing at each level?
Integration tests - Testing complete game flows:

- Happy path (all three outcomes)
 - Validation (double-commit, wrong nonce rejected)
- Access control (only authorized players)
- State management (no double reveals)

Used helper functions to reduce duplication. Each test simulates a real user journey through the contract.

# Why no E2E tests? 
- The task focuses on contract testing, not UI. E2E would require building test infrastructure beyond the scope of this exercise (at least in the format I'd consider them to be E2E).

## If I had more time: What would you extend or polish in your test suite, and why?
As I mentioned above i'd focus more on building up the app and doing real e2e testing

## AI coding assistance: If you used tools like Copilot or ChatGPT, what worked well and what did not for this task?
I've used claude for smart contract writing, as well as refactoring of code, what did not work well was me trying to use playwright initially
