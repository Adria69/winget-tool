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
	test_cmp expect actual &&

	test_config log.excludedecoration refs/bundle/
'

test_expect_success 'fetch file:// bundle' '
	git init fetch-file &&
	git -C fetch-file fetch --bundle-uri="file://$(pwd)/fetch-from/B.bundle" &&
	git -C fetch-file rev-parse refs/bundles/topic >actual &&
	git -C fetch-from rev-parse topic >expect &&
	test_cmp expect actual &&

	test_config log.excludedecoration refs/bundle/
'

#########################################################################
# HTTP tests begin here

. "$TEST_DIRECTORY"/lib-httpd.sh
start_httpd

test_expect_success 'fail to fetch from non-existent HTTP URL' '
	test_must_fail git fetch --bundle-uri="$HTTPD_URL/does-not-exist" 2>err &&
	grep "failed to download bundle from URI" err
'

test_expect_success 'fail to fetch from non-bundle HTTP URL' '
	echo bogus >"$HTTPD_DOCUMENT_ROOT_PATH/bogus" &&
	test_must_fail git fetch --bundle-uri="$HTTPD_URL/bogus" 2>err &&
	grep "is not a bundle" err
'

test_expect_success 'fetch HTTP bundle' '
	cp fetch-from/B.bundle "$HTTPD_DOCUMENT_ROOT_PATH/B.bundle" &&
	git init fetch-http &&
	git -C fetch-http fetch --bundle-uri="$HTTPD_URL/B.bundle" &&
	git -C fetch-http rev-parse refs/bundles/topic >actual &&
	git -C fetch-from rev-parse topic >expect &&
	test_cmp expect actual &&

	test_config log.excludedecoration refs/bundle/
'

# Do not add tests here unless they use the HTTP server, as they will
# not run unless the HTTP dependencies exist.

test_done
