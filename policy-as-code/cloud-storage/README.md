# Cloud Storage Policy as Code

This project turns a written cloud storage policy into automated checks using Open Policy Agent (OPA) and Rego. Instead of relying on someone to manually review storage settings, the policy evaluates every bucket and reports any that break the rules.

## Governance Requirement

Cloud storage used for internal systems must be protected from unauthorized access. Production buckets must not be publicly accessible, all buckets must be encrypted at rest, and every bucket must carry a data classification tag so its sensitivity is known.

## Rules and Control Mapping

| Rule | What it checks | NIST SP 800-53 Rev 5 controls |
|------|----------------|-------------------------------|
| No public production buckets | Flags any bucket in the prod environment with public access enabled | AC-3 Access Enforcement, SC-7 Boundary Protection |
| Encryption required | Flags any bucket that is not encrypted, including buckets missing the setting entirely | SC-28 Protection of Information at Rest |
| Classification tag required | Flags any bucket without a data classification tag | RA-2 Security Categorization, AC-16 Security and Privacy Attributes |

The test suite itself supports CA-2 Control Assessments by producing repeatable evidence that each rule works as intended.

## Files

| File | Purpose |
|------|---------|
| `storage.rego` | The policy with all three rules |
| `storage_test.rego` | Tests covering both failing and passing cases for each rule |
| `input.json` | Sample data with one compliant bucket, one noncompliant bucket, and one dev bucket |

## How to Run

Install [OPA](https://www.openpolicyagent.org/docs/latest/#running-opa), then from this folder run the tests.

```
opa test . -v
```

Evaluate the policy against the sample input.

```
opa eval -d storage.rego -i input.json "data.storage.deny"
```

## Expected Results

Running the policy against `input.json` flags only `finance-reports`, which fails all three rules.

```
finance-reports is a public production bucket
finance-reports is missing a classification tag
finance-reports is not encrypted
```

`citizen-records` passes every rule. `dev-scratch` is public but passes because the public access rule only applies to production.

## Testing Approach

Each test starts from a fully compliant bucket and changes one setting, so a failure points to exactly one rule. The tests check both directions. They confirm that noncompliant buckets are caught and that compliant buckets are not falsely flagged. Separate tests confirm that a missing encryption or classification field is treated as a violation, not ignored.

## What I Learned

In writing this policy, it showed me how a single sentence can become several precise and testable conditions. It also reinforced that a control is only as good as the evidence backing it up. Automated tests provide that very evidence every time the policy runs, rather than once a year during an audit.
