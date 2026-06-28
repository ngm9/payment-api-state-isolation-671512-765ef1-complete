# Payment API Terraform: Environment & State Safety

## Task Overview

A fintech payments squad manages the infrastructure for its `POST /api/payments` service from a single Terraform project. Today every environment shares one remote state location and one root configuration, so a change meant for staging can surface production resources in its plan, and concurrent automated runs sometimes fail with state errors. This is dangerous for a service that moves money: an engineer reviewing a staging change cannot trust that production is untouched. Your job is to make environment changes safe to reason about and safe to apply concurrently.

## Objectives

- A plan intended for staging currently also shows production service resources changing; after your work, a change scoped to one environment should produce a plan limited to that environment's own resources.
- Concurrent automated runs intermittently fail with state-content and lock errors; after your changes, two runs touching the same state must not corrupt it or race each other.
- The remote state today lives at a single shared location for all environments; the resolved state should give each environment an isolated state so they cannot overwrite one another.
- Sensitive and shared infrastructure (existing ECS services, IAM roles, backend bucket and lock table) must survive the change; a correct solution migrates without recreating or destroying these resources.
- The team needs a written, reviewable explanation of the isolation choice, the locking behavior on collisions, and the exact inspection steps to run before applying.

## Helpful Tips

- Review how the current backend key and root module combine every environment's resources into one state, and think about what "isolated plan" really requires.
- Consider how a remote backend can prevent two simultaneous runs from writing conflicting state, and what observable behavior the second run should see.
- Explore non-destructive ways to inspect what is currently tracked in state before changing anything, so you can prove existing resources will be preserved.
- Think about how an engineer would verify, from plan output alone, that a staging change cannot affect production.
- Analyze the tradeoffs between separating environments by configuration versus by workspace, and be ready to justify whichever you choose.

## How to Verify

- `terraform fmt -check` reports no formatting differences and `terraform validate` succeeds.
- A plan scoped to the staging environment shows only staging-owned resources and no production service changes.
- Each environment resolves to a distinct remote state location rather than one shared key.
- The backend configuration causes a second concurrent run to be blocked or refused rather than silently overwriting state.
- State inspection output (listing and showing existing resources) confirms ECS, IAM, and backend resources are tracked and would not be replaced.
- Your migration notes clearly explain the isolation approach, the lock behavior on collisions, and the pre-apply checks, with no destructive steps.