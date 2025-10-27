# An Overview of Attestations in CI (GitHub/GitLab/etc)

This article reviews how you can trust binary packages produced by CI systems through a mechanism called "attestations". The audience is software engineers who want a level of trust in the build packages they import.
I'll briefly describe the product `dk` for context, but the focus is on attestations.
There is a large set of technical references at the end for further reading on topics like reproducible builds.

TLDR:

- GitHub Actions gives you a level of trust in their attestations; GitLab CI does not yet.
- In 2025, attestations are too difficult to use without higher level tooling.

## Introduction

Let's introduce some terminology first. Docker is a well-known packaging tool. Docker takes Dockerfiles, builds binary Docker *images*, and distributes the images on Dockerhub. Java (simplified) takes Gradle scripts, builds *JARs*, and distributes the JARs on Maven Central. I'll call Docker images and the Java JARs **"packages"** for the lack of a better word.

The key idea is that packages are binary, can represent a full application or a library, and are produced by some build process.

Let's get back to the problem. How do we get a level of trust in these binary packages? One way is to use an **attestation**: a cryptographically signed document that associates a set of claims to a software environment and software packages. If you can trust the signer and their cryptography, you can trust the claim. The number of claims, and the strength of each claim, are the things that give you the level of trust.

There are three broad categories of claims someone can make about the build process that generates a binary package:

1. A claim about the state of the build environment *before* the build process.
2. A claim about the state of the build environment *during* the build process.
3. A claim about the state of the build environment *after* the build process.

We might have a build machine with dedicated CPUs, encrypted memory to prevent tampering and eavesdropping, a read-only filesystem, and very limited interaction with the outside world. Most cloud vendors offer this "Trusted Execution Environment" build machine: AWS Nitro Enclaves, Azure and Google Confidential VMs, etc. These same cloud vendors can typically produce a signed document (attestation) stating exactly which operating system was present and what the checksums of the filesystem were *before* the build process began. So when you hear "Trusted Execution Environment" you should mentally place them in the *before* category of claims.

I won't talk much about the *during* claims. These claims say exactly what was running on the machine, and protect against tampering during a build process. [SLSA Level 3](#technical-references) has more details.

I'll focus instead on the *after* claims. These claims say that a file (ex. a binary package) was created on the build machine, and the file had a SHA-256 checksum (ex. `9a9179c5c385852f228a7b6f884ed7d2d94ede8311babbf8836c3e7f91211f72`). Any files (binary packages) produced *outside the build machine* won't have a valid claim. That is, binary packages that are produced on a developer machine or an attacker's machine won't have a valid claim. [SLSA Level 2](#technical-references) formalizes these claims if you want to explore the technical aspects deeper.

The *after* claims (SLSA Level 2) are a big deal. If you can trust GitHub is producing valid attestations, and your upstream package maintainer asks GitHub to provide attestations for the upstream GitHub Actions workflow, then you can verify that the upstream binary package was created directly in GitHub Actions. You have taken direct human manipulation of the binary packages out of the loop.

At the same time, don't get too enthusiastic about SLSA Level 2 (ie. the *after* claims).
The claims **do not** establish a strong link between the source code and the build artifacts. Your upstream package may, for example, have used a compromised GitHub Action that modifies the build artifacts.

That's it as an introduction to attestations.

## Practical Example

`dk` is a build and packaging tool similar to Docker and Nix. Both Docker and Nix are "distributed" in that you can import binary packages from the centrally managed "nixpkgs" or DockerHub. `dk` is also distributed but rather than packages being centrally managed, the packages are loosely federated in CI systems like GitHub Actions. `dk` is a good example because the steps it performs to create and validate attestations are the same steps you would be doing manually.

The build system in `dk` has two major components:

- The "valuestore" is a key-value store. The valuestore contains the intermediate build artifacts. More details are in the ["gg" build system paper](#technical-references).
- The "tracestore" is searchable log of successful builds. More details are in the [Build systems à la carte paper](#technical-references).

The basic idea to build a package with attestations is:

1. Your upstream package builds or bundles the application or library with `dk` in CI (ex. GitHub Actions or GitLab CI/CD). The side-effect of the build are new entries in the valuestore and the tracestore.
2. The upstream CI vendor provides the cryptographic proof (the "attestation") that *after* the build the valuestore and tracestore had specific contents.
3. You or your users "import" the new valuestore and tracestore (the "package") into your local valuestores and tracestores.

In GitHub/GitLab the packaging of an upstream package looks like:

```text
┌───────────────────────────────────────────────────────────┐
│ Figure 1. CI: GitHub Actions / GitLab CI/CD               │
┼───────────────────────────────────────────────────────────┼
│                                    ┌──────────┐           │
│  1. Build app/library with "dk"    │Valuestore│           │
│                              ┌────►│          │           │
│  .. Side-effect: New entries │     └──────────┘           │
│                              │     ┌──────────┐           │
│                              │     │Tracestore│           │
│                              └────►│          │           │
│                                    └──────────┘           │
│                                                           │
│  2. Create "values.json" manifest with "dk"               │
│                      │             ┌────────────┐         │
│                      └────────────►│values.json │         │
│                                    └────────────┘         │
│  3. Ask GitHub (etc.) to make attestation                 │
│                                       │                   │
│  4. Make a release for a git tag      │                   │
│             │                 │       │                   │
└─────────────┼─────────────────┼───────┼───────────────────┘
              ▼                 │       ▼
   ┌─────────────────────┐      │   ┌───────────────┐
   │ Release             │      │   │L2 Attestation │
   │ -------             │      │   │-------------- │
   │ Tag:      1.2.3 ◄───┼──────┘   │               │
   │ Download artifacts: │          │Signature on:  │
   │  1. Valuestore      │          │ 1. Valuestore │
   │  2. Tracestore      │          │ 2. Tracestore │
   │  3. values.json     │          │ 3. values.json│
   └─────────────────────┘          └───────────────┘
```

The attestation establishes that GitHub/GitLab observed
the artifacts (the valuestore, the tracestore and values.json)
after the build and recorded their SHA-256 checksums.

It is useful to see what the attestations look like.

For the GitHub Actions release <https://github.com/diskuv/dk/releases/tag/2.4.202510250001> with the following files:

```text
Release.Darwin_arm64.oc504_wd64.tracestore
...
Release.Windows_x86_64.oc504_wd64.tracestore
Release.Windows_x86_64.values.json
Release.Windows_x86_64.valuestore.zip
values.json
```

we have the text representation of the GitHub SLSA Level 2 attestation <https://github.com/diskuv/dk/attestations/12419823>:

| Name                                       | Value                                                                   |
| ------------------------------------------ | ----------------------------------------------------------------------- |
| Commit                                     | 79259e4f0768ba4f55179d443433c673a44804e4                                |
| Build Summary                              | /diskuv/dk/actions/runs/18810737212/attempts/1                          |
| Workflow File                              | .github/workflows/distribute-2.4.yml@refs/tags/2.4.202510250001         |
| **CERTIFICATE**                            |                                                                         |
| Build Config Digest                        | 79259e4f0768ba4f55179d443433c673a44804e4                                |
| ...                                        |                                                                         |
| Issuer                                     | `https://token.actions.githubusercontent.com`                           |
| **SUBJECTS**                               |                                                                         |
| Release.Darwin_arm64.oc504_wd64.tracestore | sha256:e7bbb6848ff5845034ddba1e4bb5c01a5940c5ea7caf151bdcd15224cef92d6d |
| ...                                        |                                                                         |
| Release.Windows_x86_64.valuestore.zip      | sha256:d3fe708a5f7ea4dae5e02abe67b39cd513ddb4f96f70b703fa9b300cf0f6a692 |
| values.json                                | sha256:d5eace2505784fe26b70f272abc2d613f500cc2a02f4937d56ad972849007259 |

So you or someone malicious could try to upload new artifacts to
the GitHub/GitLab release, but the "SUBJECTS" checksums will change
to values that GitHub/GitLab does not know about. When the attestation
is verified later, GitHub/GitLab will say "I can't attest that I know the
SHA-256 checksums of those files", and the verification will fail.

Let's move onto the desktops or servers where you or your users import the package.
There are a lot of steps, and sadly they show the **complexity of verifying attestations**:

```text
   ┌────────────────────┐           ┌───────────────┐
   │ Release            │           │L2 Attestation │
   │ -------            │           │-------------- │
   │ Tag:      1.2.3    │           │               │
   │ Download links to: │           │Signature on:  │
   │  1. Valuestore     │           │ 1. Valuestore │
   │  2. Tracestore     │           │ 2. Tracestore │
   │  3. values.json    │           │ 3. values.json│
   └──────────┬─────────┘           └─────┬─────────┘
              │                           │
              │      ┌───────────────┐    │
              │      │ Trusted Roots │───────────┐
              │      └───────────────┘    │      │
              │                           │      │
┌─────────────┼───────────────────────────┼──────┼──────┐
│             ▼                           │      │      │
│  1. Download Release                    │      │      │
│                                         ▼      │      │
│  2. Use CI-specific tool to get Attestation    │      │
│                                                ▼      │
│  3. Periodically download CI-specific Trusted Roots   │
│                                                       │
│  4. Verify Attestation with Trusted Roots             │
│                                                       │
│  5. Verify Release with Attestation                   │
│                                                       │
│  6. Merge downloaded valuestore and tracestore        │
│     with local valuestore and tracestore              │
│                                                       │
│     ┌───────────────────┐  ┌───────────────────┐      │
│     │ Merged valuestore │  │ Merged tracestore │      │
│     └───────────────────┘  └───────────────────┘      │
│                                                       │
│  7. Do something (unpack, incrementally build, etc.)  │
│     the build output in the merged valuestore.        │
├───────────────────────────────────────────────────────┼
│ Figure 2. Desktop/Server                              │
└───────────────────────────────────────────────────────┘
```

Typically¹ you'll need to do all the steps in Figure 2 manually
each time there is a release, although:

- step 3 and step 4 may be combined into one step
- step 6 will change based on your specific build process

Otherwise, the SLSA materials (Trusted Roots, attestations, etc.) are downloaded and checked on your desktop and server in a manner similar to how your browser downloads and verifies TLS materials (Root CA authorities, certificates, etc.).

There are two weaknesses with verifying attestations this way:

1. Git tags are *mutable*. I can make a git tag, make a GitHub release from that git tag, and then change that git tag. In GitHub you can and should enable "immutable" git tags with <https://docs.github.com/en/code-security/supply-chain-security/understanding-your-software-supply-chain/immutable-releases>, but it [breaks attestations](https://github.com/actions/attest-build-provenance/issues/734). Hopefully that will get fixed soon, but even when fixed it will be easy to forget to enable immutable Git tags.
2. You have to scale the verification steps to your transitive dependencies. That could be hundreds of packages. In other words, **verification is too much to ask software engineers to do.** Today your browser does TLS verification automatically; we need better tools to do SLSA verification automatically (yes, consider that my one shameless plug for `dk`).

¹ `dk` reduces Figure 2 to two (2) steps. And it deals with the dependencies (ex. a GitHub project depending on another GitHub project). I'll add a link here when the docs for how `dk` simplifies attestations are done. Super-curious people can look at the cram tests in `distribute.t/` and `import-gh-l2.t/`.

## Next Steps

Check your CI vendor's status. Some vendors may need a gentle nudge to close out their issues.

| Vendor                       | Status              | Last Edit  |
| ---------------------------- | ------------------- | ---------- |
| GitHub                       | Level 2             | 2025-10-24 |
| GitHub                       | Level 3             | 2025-10-24 |
| GitLab                       | incomplete² Level 2 | 2025-10-24 |
| Google Cloud Build           | Level 2             | 2025-10-24 |
| Google Cloud Build           | Level 3             | 2025-10-24 |
| Microsoft Azure Attestations | TEE                 | 2025-10-24 |

² GitLab is not SLSA Level 2 compliant. See [GitLab SLSA Level 2 gaps](#technical-references).

> Please post an issue if you have an update or addition!

TEE ("trusted execution environment") have *before* claims that are described in the [Introduction](#introduction). And there is a way to convert the *before* claims into *after* claims (actually, stronger than that). You'll have a fair bit of work implementing [Attestable Builds: compiling verifiable binaries on untrusted systems using trusted execution environments](#technical-references), or ask the [Light Squares](https://lightsquares.dev/) company for help.

Disclosures: Except for GitLab, I am unaffliated with any company mentioned in this article. With GitLab, the company I run (Diskuv) is a GitLab customer (both Enterprise and Open Source).

Also, if you work for / have influence with the following CI providers, please nudge them with:

- GitHub: Please do not require `GITHUB_TOKEN` authentication to download attestations (Figure 2. Step 2). Use rate-limiting on a public REST API, etc. Signing into the GitHub CLI with a GITHUB_TOKEN is a major usability blocker for automated verification. <https://github.com/cli/cli/issues/12030> (thumbs up to help get it prioritized)
- GitHub: Please make it so that attestations can be generated when the git tags are immutable. <https://github.com/actions/attest-build-provenance/issues/734> (thumbs up to help get it prioritized)
- GitLab: Please close the epics for SLSA Level 2.

## Technical References

Attestable Builds and Reproducible Builds

- Building Secure and Reliable Systems - a book by Google. Chapter 14: Deploying Code. <https://google.github.io/building-secure-and-reliable-systems/raw/ch14.html>
- SLSA security levels: <https://slsa.dev/spec/v1.0/levels>
- SLSA Build Environment track. <https://slsa.dev/spec/draft/build-env-track-basics>

Mechanisms

- Attestable Builds: compiling verifiable binaries on untrusted systems using trusted execution environments: <https://www.cl.cam.ac.uk/techreports/UCAM-CL-TR-1002.pdf>
- OpenBSD signify key: <https://www.openbsd.org/papers/bsdcan-signify.html>

CI Systems

- GitHub SLSA Level 2: <https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations#generating-artifact-attestations-for-your-builds>
- GitHub SLSA Level 3: <https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/increase-security-rating>
- GitLab SLSA Level 2 gaps: <https://gitlab.com/groups/gitlab-org/-/epics/15859#note_2540189548>
- Safeguarding builds on Google Cloud Build with SLSA: <https://slsa.dev/blog/2022/12/gcb-slsa-verification>

Build Systems

- `gg` build system paper: <https://www.usenix.org/system/files/atc19-fouladi.pdf>
- Build systems à la carte paper: <https://www.cambridge.org/core/journals/journal-of-functional-programming/article/build-systems-a-la-carte-theory-and-practice/097CE52C750E69BD16B78C318754C7A4>

## Log

- 2025/10/27. Added this section. Added issue link for GitHub auth. Added subsection titles to Technical References. Amended intro sentence to add reproducible builds as further reading. Added "Building Secure and Reliable Systems" and "SLSA Build Environment track" references.
- 2025/10/25. <https://lobste.rs/s/vflxfb/overview_attestations_ci>

-- Jonah
