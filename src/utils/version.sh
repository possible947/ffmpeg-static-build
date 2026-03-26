#!/bin/bash

# Returns: 0 if ver1 >= ver2, 1 otherwise
version_gte() {
  local ver1="$1"
  local ver2="$2"

  if [[ -z "$ver1" || -z "$ver2" ]]; then
    return 1
  fi

  local IFS='.'
  read -ra V1 <<< "$ver1"
  read -ra V2 <<< "$ver2"

  local max_len=${#V1[@]}
  [[ ${#V2[@]} -gt $max_len ]] && max_len=${#V2[@]}

  for ((i=0; i<max_len; i++)); do
    local n1="${V1[i]:-0}"
    local n2="${V2[i]:-0}"

    n1="${n1%%[a-z]*}"
    n2="${n2%%[a-z]*}"

    if (( n1 > n2 )); then
      return 0
    elif (( n1 < n2 )); then
      return 1
    fi

    if [[ "$n1" == *[a-z]* && "$n2" != *[a-z]* ]]; then
      return 1
    elif [[ "$n2" == *[a-z]* && "$n1" != *[a-z]* ]]; then
      return 0
    fi

    n1="${n1#0}" || n1=0
    n2="${n2#0}" || n2=0
  done

  return 0
}

version_satisfies() {
  local current="$1"
  local minimum="$2"

  if ! version_gte "$current" "$minimum"; then
    return 1
  fi

  return 0
}
