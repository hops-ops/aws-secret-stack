### What's changed in v0.13.1

* fix(usages): add 'eso' discriminator to delete-helm Usage name (by @patrickleet)

  Generic Usage names like '<name>-delete-helm-before-pod-identity'
  collide with sibling stacks (e.g. aws-lbc-stack) that share the same
  XR metadata.name. Kubernetes rejects the resulting double
  'controller: true' ownerReference.

  Rename to '<name>-delete-helm-eso-before-pod-identity' so the Usage
  is uniquely owned by this stack regardless of co-installed siblings.

  See xrd-authoring/references/usages.md "Avoiding Cross-Stack Name
  Collisions" for the pattern.


See full diff: [v0.13.0...v0.13.1](https://github.com/hops-ops/aws-secret-stack/compare/v0.13.0...v0.13.1)
