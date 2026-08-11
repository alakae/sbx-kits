## Blocked Network Requests

When an outbound request inside the sandbox is blocked by network policy
(a `403` from the proxy, with a "no matching allow rule" / "blocked by
default deny policy" detail):

1. Always show the exact `sbx policy allow network` command needed to
   unblock it, scoped to this sandbox only:

   ```bash
   sbx policy allow network --sandbox $SANDBOX_VM_ID <domain>
   ```

   Do not suggest the global (all-sandboxes) form unless the user asks
   for it.

2. Use the AskUserQuestion tool and offer exactly two options:
   - Run the command and continue: the user runs it on the host, then
     confirms so the request can be retried.
   - Deny: the user does not want to allow this access.

3. If the user selects deny, stop the task. Do not attempt workarounds
   (alternate domains, mirrors, cached copies, different flags, retries)
   to reach the blocked host.
