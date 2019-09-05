#!/bin/sh

test_description='check handling of .gitmodule path'
. ./test-lib.sh

test_expect_success MINGW 'submodule paths disallows trailing spaces' '
	git init upstream &&
	(
		cd upstream &&
		test_commit initial
	) &&

	git init super &&
	test_must_fail git -C super submodule add ../upstream "sub " &&

	: add "sub", then rename "sub" to "sub ", the hard way &&
	git -C super submodule add ../upstream sub &&
	tree=$(git -C super write-tree) &&
	git -C super ls-tree $tree >tree &&
	sed "s/sub/sub /" <tree >tree.new &&
	tree=$(git -C super mktree <tree.new) &&
	commit=$(echo with space | git -C super commit-tree $tree) &&
	git -C super update-ref refs/heads/master $commit &&

	test_must_fail git clone --recurse-submodules super dst 2>err &&
	test_i18ngrep "sub " err
'

test_done
