### What's changed in v0.13.0

* chore(makefile): add generate-configuration target (by @patrickleet)

  Wires hops validate generate-configuration as a prerequisite of
  validate:all / validate / validate:% so configuration.yaml is
  regenerated from upbound.yaml before each validation run.

  The `.gitignore` entry was auto-appended by the hops CLI on first
  run — configuration.yaml is a generated artifact.

  Implements [[tasks/update-xrd-makefiles-generate-config]]

* feat(deps): update dependency aws-pod-identity to v0.10.1 (#17) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>


See full diff: [v0.12.0...v0.13.0](https://github.com/hops-ops/aws-secret-stack/compare/v0.12.0...v0.13.0)
