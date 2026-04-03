### What's changed in v0.11.0

* feat: sops (#16) (by @patrickleet)

  <!-- This is an auto-generated comment: release notes by coderabbit.ai -->
  ##### Summary by CodeRabbit

  * **New Features**
    * Configurable SecretStore (namespaced or cluster scope) and optional SOPS KMS key; KMS ARN surfaced in status.

  * **Documentation**
    * Expanded README with SecretStore/SOPS examples, role/tag examples, and added make e2e development command.

  * **Tests**
    * Added render and e2e tests covering KMS key, SecretStore rendering, scope variants, status wiring, and tagging.

  * **Chores**
    * CI/Makefile updated to run additional observed-resource scenarios; e2e workflow timing/cleanup and resource deletion adjusted; added mock observed-resource fixtures.
  <!-- end of auto-generated comment: release notes by coderabbit.ai -->


See full diff: [v0.10.0...v0.11.0](https://github.com/hops-ops/aws-secret-stack/compare/v0.10.0...v0.11.0)
