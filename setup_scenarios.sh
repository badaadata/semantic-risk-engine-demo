#!/usr/bin/env bash
# Creates one branch + PR per demo scenario. Run from the repo root on main,
# after the repo is pushed to GitHub and SEMANTIC_RISK_API_KEY is set as a secret.
# Requires: gh CLI authenticated.
set -euo pipefail

declare -A TITLES=(
  [s1_join_flip]="Fix customer join"
  [s2_filter_removed]="Simplify orders CTE"
  [s3_grain_change]="Add order_date to revenue rollup"
  [s4_metric_redefined]="Refactor total_revenue calc"
  [s5_cosmetic_only]="Reformat customer_revenue"
)
# Innocent-looking titles on purpose: the demo point is that the diff LOOKS harmless.

for s in s1_join_flip s2_filter_removed s3_grain_change s4_metric_redefined s5_cosmetic_only; do
  git checkout main >/dev/null 2>&1
  git checkout -b "demo/$s"
  cp "scenarios/$s.sql" models/marts/customer_revenue.sql
  git commit -am "${TITLES[$s]}"
  git push -u origin "demo/$s"
  gh pr create --title "${TITLES[$s]}" \
    --body "Routine model change - see the Semantic Risk Engine comment below."
done
git checkout main
echo "5 PRs opened. Verdicts should appear within a minute of each PR's CI run."
