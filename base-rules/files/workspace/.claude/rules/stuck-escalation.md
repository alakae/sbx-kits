## Escalation When Stuck

When you are stuck on a problem — unable to resolve an error, reproduce a fix, or find a
root cause after genuine investigation — do not keep retrying blindly.

Instead, compose a deep-research prompt for the human to paste into a web-connected AI
(e.g. Perplexity, Gemini Deep Research). The prompt must:

1. **Describe the setup** — relevant languages, frameworks, versions, OS, and config.
2. **State the problem clearly** — what you tried, what failed, and the exact error or
   unexpected behaviour.
3. **Ask targeted questions** — specific things the research AI should look for: known
   bugs, open issues, workarounds, relevant discussions.

Present the prompt in a fenced code block so the human can copy it directly.
After presenting it, stop and wait — do not attempt further fixes until the human
returns with findings.