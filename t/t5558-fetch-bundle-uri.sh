#!/bin/sh

test_description='test fetching bundles with --bundle-uri'

. ./test-lib.sh

test_expect_success 'fail to fetch from non-existent file' '
	test_must_fail git fetch --bundle-uri="$(pwd)/does-not-exist" 2>err &&
	grep "failed to download bundle from URI" err
'

test_expect_success 'fail to fetch from non-bundle file' '
	echo bogus >bogus &&
	test_must_fail git fetch --bundle-uri="$(pwd)/bogus" 2>err &&
	grep "is not a bundle" err
'

test_expect_success 'create bundle' '
	git init fetch-from &&
	git -C fetch-from checkout -b topic &&
	test_commit -C fetch-from A &&
	test_commit -C fetch-from B &&
	git -C fetch-from bundle create B.bundle topic
'

test_expect_success 'fetch file bundle' '
	git init fetch-to &&
	git -C fetch-to fetch --bundle-uri="$(pwd)/fetch-from/B.bundle" &&
	git -C fetch-to rev-parse refs/bundles/topic >actual &&
	git -C fetch-from rev-parse topic >expect &&
	test_cmp expect actual
'

test_done
