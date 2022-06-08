#!/bin/sh

test_description='test operations trying to overwrite refs at worktree HEAD'

. ./test-lib.sh

test_expect_success 'setup' '
	for i in 1 2 3 4
	do
		test_commit $i &&
		git branch wt-$i &&
		git worktree add wt-$i wt-$i || return 1
	done &&

	# Create a server that updates each branch by one commit
	git clone . server &&
	git remote add server ./server &&
	for i in 1 2 3 4
	do
		git -C server checkout wt-$i &&
		test_commit -C server A-$i || return 1
	done
'

test_expect_success 'refuse to overwrite: checked out in worktree' '
	for i in 1 2 3 4
	do
		test_must_fail git branch -f wt-$i HEAD 2>err
		grep "cannot force update the branch" err &&

		test_must_fail git branch -D wt-$i 2>err
		grep "Cannot delete branch" err || return 1
	done
'

test_expect_success 'refuse to overwrite during fetch' '
	test_must_fail git fetch server +refs/heads/wt-3:refs/heads/wt-3 2>err &&
	grep "refusing to fetch into branch '\''refs/heads/wt-3'\''" err &&

	# General fetch into refs/heads/ will fail on first ref,
	# so use a generic error message check.
	test_must_fail git fetch server +refs/heads/*:refs/heads/* 2>err &&
	grep "refusing to fetch into branch" err
'

test_expect_success 'refuse to overwrite: worktree in bisect' '
	test_when_finished test_might_fail git -C wt-4 bisect reset &&

	(
		git -C wt-4 bisect start &&
		git -C wt-4 bisect bad HEAD &&
		git -C wt-4 bisect good HEAD~3
	) &&

	test_must_fail git branch -f wt-4 HEAD 2>err &&
	grep "cannot force update the branch '\''wt-4'\'' checked out at" err &&

	test_must_fail git fetch server +refs/heads/wt-4:refs/heads/wt-4 2>err &&
	grep "refusing to fetch into branch '\''refs/heads/wt-4'\''" err
'

. "$TEST_DIRECTORY"/lib-rebase.sh

test_expect_success 'refuse to overwrite: worktree in rebase' '
	test_when_finished test_might_fail git -C wt-4 rebase --abort &&

	(
		set_fake_editor &&
		FAKE_LINES="edit 1 2 3" \
			git -C wt-4 rebase -i HEAD~3 >rebase &&
		git -C wt-4 status
	) &&

	test_must_fail git branch -f wt-4 HEAD 2>err &&
	grep "cannot force update the branch '\''wt-4'\'' checked out at" err &&

	test_must_fail git fetch server +refs/heads/wt-4:refs/heads/wt-4 2>err &&
	grep "refusing to fetch into branch '\''refs/heads/wt-4'\''" err
'

test_done
