#!/bin/bash

set -e

TOP_DIR="$(cd "$(dirname "$0")"; echo "$PWD")"

declare -A images

set -x
process_compose() {
	declare image
	while [[ $# -gt 0 ]]; do
		for image in $(cd "$1"; docker-compose config|sed -n 's,image: docker.brainfood.com/shared/\([^:]*\):.*,bf-\1,p'); do
			images[$image]=1
		done
		shift
	done
}

if [[ -f docker-compose.yml ]]; then
	process_compose "$PWD"
else
	process_compose $(find "$TOP_DIR/compose" -name docker-compose.yml -printf '%h\n')
fi

if [[ ${#images[@]} -gt 0 ]]; then
	make -C "$TOP_DIR" "${!images[@]}"
fi
