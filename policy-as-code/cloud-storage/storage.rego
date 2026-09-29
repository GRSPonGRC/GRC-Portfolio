package storage

import rego.v1

deny contains msg if {
	some bucket in input.buckets
	bucket.public == true
	bucket.environment == "prod"
	msg := sprintf("%s is a public production bucket", [bucket.name])
}

deny contains msg if {
	some bucket in input.buckets
	not bucket.encrypted
	msg := sprintf("%s is not encrypted", [bucket.name])
}

deny contains msg if {
	some bucket in input.buckets
	not bucket.classification
	msg := sprintf("%s is missing a classification tag", [bucket.name])
}
