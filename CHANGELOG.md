### What's changed in v0.16.0

* feat: Burstable resource defaults for external-secrets (operator + cert-controller + webhook) (by @patrickleet)

  All three pods shipped as BestEffort by default. Verified on pat-local:
  new pods rh2mx (controller) and lrxpw (cert-controller) and cfq2w
  (webhook) transitioned to Burstable QoS after install.

  Implements [[tasks/cluster-wide-resource-right-sizing-p95-observation]] tier-1 #5

* feat(deps): update crossplane-contrib/function-auto-ready docker tag to v0.6.5 (#22) (by @renovate[bot])

  Co-authored-by: renovate[bot] <29139614+renovate[bot]@users.noreply.github.com>


See full diff: [v0.15.0...v0.16.0](https://github.com/hops-ops/aws-secret-stack/compare/v0.15.0...v0.16.0)
