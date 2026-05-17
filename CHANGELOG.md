### What's changed in v0.15.0

* feat(secretstack): allow ESO IRSA role to write secrets under push/* (by @patrickleet)

  Adds a `WritePushedSecrets` IAM statement granting `secretsmanager:*` on
  `arn:aws:secretsmanager:*:*:secret:push/*`, scoped narrowly so the
  existing read-everywhere policy stays untouched. Pairs with the new
  PushSecret flow in AuthStack: the chart-managed iam-admin PAT gets
  pushed to AWS SM at `push/<clusterName>/zitadel-credentials` for
  consumers to pull and assemble into a Zitadel ProviderConfig.

  The `push/` top-level prefix is the convention for AuthStack-style
  publishers; the wildcard keeps IAM as one statement regardless of how
  many stacks adopt the pattern. Read scope is unchanged.

  Verified live on pat-local: SecretStack composition redeploys cleanly,
  PushSecret transitions from AccessDenied to Synced after the ESO
  controller picks up the new session token (one rollout restart needed
  the first time; subsequent reconciles inherit fresh creds).


See full diff: [v0.14.0...v0.15.0](https://github.com/hops-ops/aws-secret-stack/compare/v0.14.0...v0.15.0)
