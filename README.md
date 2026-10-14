# PR validation setup

These steps are a follow-up to the
[Expand your team with Copilot exercise](https://github.com/skills/expand-your-team-with-copilot),
where Copilot coding agent tackles issues directly on GitHub without a local
coding environment. After completing the exercise, use these tests, workflow,
and ruleset instructions to add PR-based validation to your exercise repository.
The same follow-up can be used each time you run the exercise in a new repository.

The **PR validation** workflow compiles and tests the application in `src/`.
Its **Build and test** check can be required before a pull request is merged.

## Prepare the required check

1. Ensure GitHub Actions is enabled under **Settings > Actions > General**.
2. Push the workflow and tests, then open a PR into `main`.
3. Confirm **Build and test** appears in the PR's **Checks** tab and succeeds.
   GitHub must have seen the check recently before you can select it in a ruleset.
4. Merge the setup PR so the workflow is on the default branch.

Python and frontend reports are available under the workflow run's **Artifacts**
section as `python-test-reports` and `frontend-test-reports`, retained for 14 days.

## Create a branch ruleset for PR-based validation

You need repository admin access or a role with permission to edit rules.
Rulesets are available for public repositories on GitHub Free; private
repository availability depends on your plan.

1. Open **Settings > Rules > Rulesets** (the sidebar may label the section
   **Rulesets**), then **New ruleset > New branch ruleset**.
2. Name it `PR validation for main` and set enforcement to **Active**.
3. Under **Target branches**, choose **Add target > Include default branch**,
   or explicitly include `main` if that is the branch you intend to protect.
4. Leave the **Bypass list** empty unless there is a documented emergency
   exception. Adding administrators or apps lets them bypass the protections.
5. Enable **Require a pull request before merging**. For team work, require
   at least one approval, dismiss stale approvals when new commits are pushed,
   and require review of the most recent reviewable push. A solo repository
   may need zero required approvals because authors cannot approve their own PRs.
6. Enable **Require status checks to pass before merging**. Search for and add
   the exact job check **Build and test**. Select **GitHub Actions** as the
   expected source if offered. Use the job name, not the workflow name
   `PR validation`, and avoid reusing it in other workflows. Click the add/plus
   control to actually add the selected check.
7. Enable **Require branches to be up to date before merging** if you want
   validation against the latest target branch. The workflow also supports
   a merge queue if you enable one later.
8. Enable **Require conversation resolution before merging**, **Block force
   pushes**, and **Restrict deletions** as appropriate. Do not enable
   **Restrict updates**: that is a separate restriction and can block normal
   PR merges for users who are not on the bypass list.
9. Save the ruleset.

## Verify enforcement

Open a disposable PR that introduces a Python syntax error or changes an expected
response. Confirm **Build and test** fails and merging is blocked. Correct the
change and confirm the check succeeds; merging must still wait for any required
review or conversation resolution.

Also confirm direct pushes to the protected branch are rejected for a user
without bypass rights. Do not test destructive changes on `main` itself.

If the required check stays pending, check that Actions is enabled, approve
fork workflow runs where necessary, and ensure the required name matches
**Build and test** exactly. Renaming the job requires updating the ruleset.

## Test notes

**Known expected failure:** seeded teacher passwords use Argon2, but login
compares SHA-256 hashes. The seeded-login test is marked as a strict expected
failure. After fixing login, remove its `xfail` marker; an unexpected pass
will otherwise fail validation.

**Dependency caveat:** `src/requirements.txt` includes the legacy
`argon2==0.1.10` package, which failed to build on Windows. For local tests,
`requirements-test.txt` provides `argon2-cffi`, the implementation used by the
application. CI also installs `src/requirements.txt`.

References:
[creating rulesets](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-rulesets/creating-rulesets-for-a-repository)
and [required status checks](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches#require-status-checks-before-merging).
