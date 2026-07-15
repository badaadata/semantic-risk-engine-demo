# semantic-risk-engine-demo - Semantic Risk Engine demo project

A minimal, compilable dbt project (DuckDB, no warehouse) with **5 pre-built pull requests**,
one per demo scenario from `docs/demo_script.md`. Each PR looks like a routine model change;
the Semantic Risk Engine comment tells the real story.

| PR branch | Change | Expected verdict |
|---|---|---|
| demo/s1_join_flip | LEFT JOIN -> INNER JOIN | HIGH - JOIN MODIFIED (rows may be dropped) |
| demo/s2_filter_removed | WHERE status='completed' dropped (inside CTE) | HIGH - FILTER REMOVED, located cte[orders]:: |
| demo/s3_grain_change | order_date added to GROUP BY | HIGH - GRAIN MODIFIED (+ CRITICAL MODEL flag) |
| demo/s4_metric_redefined | SUM -> COUNT under unchanged alias | MEDIUM - AGGREGATION MODIFIED |
| demo/s5_cosmetic_only | Reformat + reorder + comment, zero semantic change | No semantic risks detected |
| demo/s6_ltv_join_flip | LTV join type shift (LEFT -> INNER) | HIGH - JOIN MODIFIED |
| demo/s7_equivalent_condition | Swap operands and reorganize logic | No semantic risks detected (Equivalent check) |
| demo/s8_add_lookup_join | Add lookup join/active filter | HIGH - JOIN MODIFIED (LEFT -> INNER) |
| demo/s9_long_query_mix | Mega query with 10 window functions and alias changes | HIGH - QUALIFY ADDED, 10 LOW - WINDOW_FUNCTION ADDED, 9 INFO - COLUMN ALIAS_MODIFIED |
| demo/s10_all_severities | Multi-severity logic errors in customer LTV | 3 HIGH, 2 MEDIUM, 1 LOW (Mega consolidated report) |
| demo/s11_multi_file | Refactor logic changes across 5 models | 6 HIGH, 12 MEDIUM (Multi-file risk report) |

`customer_revenue` is tagged `semantic_risk_critical: true`, so s3 also demos the
critical-model marker + downstream annotation.

## One-time setup (~10 min)

1. Create a **public** repo `badaadata/sre-demo`; push this folder's contents as `main`.
2. Repo Settings -> Secrets -> Actions: add `SEMANTIC_RISK_API_KEY` (a demo key you issue
   to yourself via `api/scripts/issue_key.py`).
3. Run `./setup_scenarios.sh` (needs `gh` CLI authenticated).
4. Wait for CI on each PR; confirm all five verdicts match the table above.
5. Leave the PRs open forever - they ARE the demo. Re-run a workflow before calls if the
   comments are stale.

Compile locally to sanity-check: `pip install dbt-duckdb && DBT_PROFILES_DIR=. dbt seed && dbt compile`.
