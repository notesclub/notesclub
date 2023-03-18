#!/usr/bin/env bash
# This is used in dev mode

mix test
mix credo --strict
mix dialyzer
