#!/usr/bin/env bash
# Creates one branch + PR per demo scenario. Run from the repo root on main,
# after the repo is pushed to GitHub and SEMANTIC_RISK_API_KEY is set as a secret.
# Requires: gh CLI authenticated.
set -euo pipefail

# scenario -> PR title (innocent-looking on purpose: the diff LOOKS harmless)
declare -A TITLES=(
  [s1_join_flip]="Fix customer join"
  [s2_filter_removed]="Simplify orders CTE"
  [s3_grain_change]="Add order_date to revenue rollup"
  [s4_metric_redefined]="Refactor total_revenue calc"
  [s5_cosmetic_only]="Reformat customer_revenue"
  [s6_ltv_join_flip]="Tidy customer_ltv joins"
  [s7_equivalent_condition]="Normalize join condition order"
  [s8_add_lookup_join]="Add first-order date to customer_ltv"
)
# scenario -> the model file it modifies
declare -A TARGETS=(
  [s1_join_flip]="models/marts/customer_revenue.sql"
  [s2_filter_removed]="models/marts/customer_revenue.sql"
  [s3_grain_change]="models/marts/customer_revenue.sql"
  [s4_metric_redefined]="models/marts/customer_revenue.sql"
  [s5_cosmetic_only]="models/marts/customer_revenue.sql"
  [s6_ltv_join_flip]="models/marts/customer_ltv.sql"
  [s7_equivalent_condition]="models/marts/customer_ltv.sql"
  [s8_add_lookup_join]="models/marts/customer_ltv.sql"
)

for s in s1_join_flip s2_filter_removed s3_grain_change s4_metric_redefined s5_cosmetic_only \
         s6_ltv_join_flip s7_equivalent_condition s8_add_lookup_join; do
  git checkout main >/dev/null 2>&1
  git checkout -b "demo/$s"
  cp "scenarios/$s.sql" "${TARGETS[$s]}"
  git commit -am "${TITLES[$s]}"
  git push -u origin "demo/$s"
  gh pr create --title "${TITLES[$s]}" \
    --body "Routine model change - see the Semantic Risk Engine comment below."
done
git checkout main
echo "8 PRs opened. Verdicts should appear within a minute of each PR's CI run."
