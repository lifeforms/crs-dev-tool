#!/bin/sh
config_file=~/.crs

crs_help() {
	echo "Code:"
	echo "  crs branch                 List available CRS development branches"
	echo "  crs clean <branch>         Remove everything and checkout your fork"
	echo "  crs merge                  Merge upstream changes into your fork"
	echo
	echo "Testing:"
	echo "  crs test                   Run full test suite on your CRS copy"
	echo "  crs test <ruleid>          Run only a single rule's .yaml file"
	echo
	echo "Debugging:"
	echo "  crs serve                  Run a web server on your CRS copy"
	echo "  crs shell                  Open bash in a running test/serve container"
	echo
	echo "Issues:"
	echo "  crs issue [<num>]          Open issue/PR [#num] page in browser"
	echo "  crs review <user>:<branch> Check out and edit somebody else's PR"
	echo
	echo "Your CRS code directory:     $basedir"
	echo "Configuration file:          $config_file"
}

check_config_file() {
	[ ! -f "$config_file" ] && {
		echo "Config file $config_file not found, creating an example version..."
		cat << EOF > $config_file
# Configuration file for crs command

# Remove comment char and set your local CRS directory:
#basedir=~/dev/crs

# Remove comment char and set your fork of the CRS on GitHub:
#remote=git@github.com:yourname/owasp-modsecurity-crs.git

# If you don't have a fork of the CRS on GitHub yet,
# first go to https://github.com/SpiderLabs/owasp-modsecurity-crs/
# and click "Fork" before setting the above variable.

# The values below usually do not have to be changed.
upstream=git@github.com:SpiderLabs/owasp-modsecurity-crs.git
upstream_web=https://github.com/SpiderLabs/owasp-modsecurity-crs/
docker_test_image=lifeforms/crs-test
EOF
		echo "Please edit config file $config_file before using this command."
		exit 2
	}
	. $config_file
}

check_defines() {
	[ -z "$basedir" ] && {
		echo "Configuration error: basedir is unset."
		echo "Please edit config file $config_file before using this command."
		exit 3
	}
	[ -z "$remote" ] && {
		echo "Configuration error: remote is unset."
		echo "Please edit config file $config_file before using this command."
		exit 4
	}
	[ -z "$upstream" ] && {
		echo "Configuration error: upstream is unset."
		echo "Please edit config file $config_file before using this command."
		exit 5
	}
	[ -z "$upstream_web" ] && {
		echo "Configuration error: upstream_web is unset."
		echo "Please edit config file $config_file before using this command."
		exit 6
	}
	[ -z "$docker_test_image" ] && {
		echo "Configuration error: docker_test_image is unset."
		echo "Please edit config file $config_file before using this command."
		exit 7
	}
}

crs_branch() {
	echo "Available branches:"
	git ls-remote --heads $upstream | grep '\d/' | awk '{print $2}' | sed s/refs\\/heads\\//'  '/g
}

crs_clean() {
	branch=$1
	[ -z "$branch" ] && {
		echo "Please supply a branch name."
		crs_branch
		exit 10
	}
	git ls-remote --heads $upstream $branch | grep $branch >/dev/null
	[ "$?" == "1" ] && {
		echo "Branch doesn't exist on upstream: $branch"
		crs_branch
		exit 11
	}

	[ -d "$basedir" ] && {
		echo "Removing contents of $basedir..."
		rm -rf $basedir || exit 12
	}
	mkdir -p $basedir || exit 13

	echo "Cloning your fork $remote..."
	cd $basedir || exit 14
	git clone -q $remote . || exit 15
	git co $branch || exit 16

	echo "Creating crs-setup.conf from example..."
	cp crs-setup.conf.example crs-setup.conf || exit 17

	echo "Adding upstream $upstream..."
	git remote add upstream $upstream || exit 18
}

crs_review() {
	user=`echo $1 | awk '{split($0,x,":"); print x[1]}'`
	branch=`echo $1 | awk '{split($0,x,":"); print x[2]}'`
	[ -z "$user" ] && {
		echo "Please supply a username."
		exit 20
	}
	[ -z "$branch" ] && {
		echo "Please supply a branch name."
		exit 21
	}

	cd $basedir || exit 22
	# We assume that the user's fork is also called 'owasp-modsecurity-git'
	git remote add $user git@github.com:$user/owasp-modsecurity-crs.git
	(git remote update $user 2> /dev/null) || {
		# Git remote update doesn't have a --quiet option and the command
		# is extremely noisy, so we silence stdout, but re-run if it fails
		# just to print the error message.
		git remote update $user
		exit 23
	}
	git fetch -q $user || exit 24
	git checkout -b $user-$branch $user/$branch || exit 25
	echo "To return to your own fork, try: git checkout v3.1/dev"
}

crs_merge() {
	cd $basedir || exit 30

	# I wonder if this works when we're on a local development branch...
	branch=`git rev-parse --abbrev-ref HEAD`
	[ -z "$branch" ] && {
		echo "Cannot find the current branch name."
		exit 31
	}

	echo "Fetching upstream..."
	git fetch -q upstream || exit 32

	echo "Merging upstream changes into your fork..."
	git merge --ff-only upstream/$branch || exit 33
	git push || exit 34
}

crs_issue() {
	url=${upstream_web}issues/$1

	# TODO: macOS specific, add Ubuntu equivalent
	/usr/bin/open $url
}

crs_test() {
	(docker pull $docker_test_image > /dev/null) || exit 50
	docker run \
		--name crs-test \
		--rm \
		-it \
		-v $basedir:/crs \
		$docker_test_image /run-tests.sh $1 || exit 51
}

crs_serve() {
	echo "Starting server at http://localhost/"
	echo "Press ^C in this terminal to stop the server."
	echo "Run 'crs shell' in another terminal to open a shell in the container."
	echo
	docker run \
		--name crs-test \
		--rm \
		-p 80:80 \
		-it \
		-v $basedir:/crs \
		$docker_test_image /serve.sh || exit 60
}

crs_shell() {
	docker exec -it crs-test bash || exit 70
}

# Main

check_config_file
check_defines

case "$1" in
	branch)
		crs_branch
		exit 0
		;;
	clean)
		crs_clean $2
		crs_merge
		exit 0
		;;
	merge)
		crs_merge
		exit 0
		;;
	issue)
		crs_issue $2
		exit 0
		;;
	review)
		crs_review $2
		exit 0
		;;
	test)
		crs_test $2
		exit
		;;
	serve)
		crs_serve
		exit 0
		;;
	shell)
		crs_shell
		exit 0
		;;
	help|-h|"")
		crs_help
		exit 1
		;;
	*)
		echo "Unknown command: $1"
		exit 8
esac