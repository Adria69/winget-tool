#!/bin/sh

test_description='check handling of .gitmodule url dash'
. ./test-lib.sh

test_expect_success 'trailing backslash is handled correctly' '
	git init testmodule &&
	(
		cd testmodule &&
		test_commit c
	) &&
	git submodule add ./testmodule &&
	: ensure that the name ends in a double backslash &&
	sed -e "s|\\(submodule \"testmodule\\)\"|\\1\\\\\\\\\"|" \
		-e "s|url = .*|url = \" --should-not-be-an-option\"|" \
		<.gitmodules >.new &&
	mv .new .gitmodules &&
	git commit -am "Add testmodule" &&
	test_must_fail git clone --verbose --recurse-submodules . dolly 2>err &&
	test_i18ngrep ! "unknown option" err
'

test_done
