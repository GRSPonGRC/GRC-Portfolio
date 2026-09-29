package storage_test

import rego.v1

import data.storage

# A bucket that meets every rule. Tests start from this and change one thing.
compliant := {
	"name": "test-bucket",
	"public": false,
	"environment": "prod",
	"encrypted": true,
	"classification": "internal",
}

# Rule 1. Production buckets must not be public

test_public_prod_bucket_denied if {
	bucket := object.union(compliant, {"public": true})
	"test-bucket is a public production bucket" in storage.deny with input as {"buckets": [bucket]}
}

test_private_prod_bucket_allowed if {
	count(storage.deny) == 0 with input as {"buckets": [compliant]}
}

test_public_dev_bucket_allowed if {
	bucket := object.union(compliant, {"public": true, "environment": "dev"})
	count(storage.deny) == 0 with input as {"buckets": [bucket]}
}

# Rule 2. Buckets must be encrypted

test_unencrypted_bucket_denied if {
	bucket := object.union(compliant, {"encrypted": false})
	"test-bucket is not encrypted" in storage.deny with input as {"buckets": [bucket]}
}

test_missing_encryption_field_denied if {
	bucket := object.remove(compliant, ["encrypted"])
	"test-bucket is not encrypted" in storage.deny with input as {"buckets": [bucket]}
}

# Rule 3. Buckets must have a data classification tag

test_missing_classification_denied if {
	bucket := object.remove(compliant, ["classification"])
	"test-bucket is missing a classification tag" in storage.deny with input as {"buckets": [bucket]}
}

# Sample input. Only finance-reports should fail, and it should fail all three rules

test_sample_input_results if {
	sample := {"buckets": [
		{"name": "citizen-records", "public": false, "environment": "prod", "encrypted": true, "classification": "confidential"},
		{"name": "finance-reports", "public": true, "environment": "prod", "encrypted": false},
		{"name": "dev-scratch", "public": true, "environment": "dev", "encrypted": true, "classification": "internal"},
	]}
	results := storage.deny with input as sample
	count(results) == 3
	every msg in results {
		startswith(msg, "finance-reports")
	}
}
