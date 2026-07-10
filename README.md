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
