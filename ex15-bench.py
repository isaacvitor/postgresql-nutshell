#!/usr/bin/env python3
# jsonb_bench_corrected.py
# Requisitos: pip install psycopg2-binary

import psycopg2
import csv
import statistics
import os
from psycopg2.extras import RealDictCursor

DB = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "database": os.getenv("DB_NAME", "exercises"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASS", "postgres")
}

OUT_CSV = "ex15-bench_results.csv"
N_RUNS = 5
SAMPLE_FOR_BYTES = 3  # how many records to estimate octet_length / pg_column_size

def main():
    conn = psycopg2.connect(**DB)
    cur = conn.cursor(cursor_factory=RealDictCursor)

    results = []

    # Pegar combinations (size, level) existentes
    cur.execute("SELECT DISTINCT size, level FROM test_jsonb_nesting ORDER BY size, level;")
    pairs = cur.fetchall()
    print(f"Found {len(pairs)} (size,level) combinations.")

    for row in pairs:
        size = int(row['size'])
        level = int(row['level'])

        # Estimar raw bytes (octet_length) e stored bytes (pg_column_size): média de SAMPLE_FOR_BYTES
        cur.execute("""
            SELECT octet_length(jb::text) AS raw_bytes, pg_column_size(jb) AS stored_bytes
            FROM test_jsonb_nesting
            WHERE size = %s AND level = %s
            LIMIT %s
        """, (size, level, SAMPLE_FOR_BYTES))
        sample_rows = cur.fetchall()
        if sample_rows:
            raw_vals = [r['raw_bytes'] for r in sample_rows if r['raw_bytes'] is not None]
            stored_vals = [r['stored_bytes'] for r in sample_rows if r['stored_bytes'] is not None]
            bytes_raw = int(sum(raw_vals) / len(raw_vals)) if raw_vals else None
            bytes_stored = int(sum(stored_vals) / len(stored_vals)) if stored_vals else None
        else:
            bytes_raw = None
            bytes_stored = None

        # montar expressões de acesso
        if level == 0:
            arrow_chain = "jb -> 'key'"
            path_expr = "jb #> '{key}'"
            subs_expr = "jb -> 'key'"
            jsonpath = "$.key"
        else:
            keys = ["obj"] * level + ["key"]
            path_array = "{" + ",".join(keys) + "}"
            arrow_chain = "jb" + "".join([f" -> 'obj'" for _ in range(level)]) + " -> 'key'"
            path_expr = f"jb #> '{path_array}'"
            subs_expr = "jb" + "".join([f" -> 'obj'" for _ in range(level)]) + " -> 'key'"
            jsonpath = "$." + ".".join(["obj"] * level + ["key"])

        operators = [
            ("arrow", arrow_chain),
            ("path", path_expr),
            ("subscript", subs_expr),
            ("jsonpath", f"jsonb_path_query_first(jb, '{jsonpath}')")
        ]

        for op_name, op_expr in operators:
            exec_times = []
            for r in range(N_RUNS):
                q = f"""
                EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
                SELECT {op_expr}
                FROM test_jsonb_nesting
                WHERE size = %s AND level = %s
                LIMIT 1;
                """
                cur.execute(q, (size, level))
                fetched = cur.fetchone()
                if not fetched:
                    exec_time = None
                else:
                    plan_json = fetched[list(fetched.keys())[0]]  # RealDictCursor returns { '?column?': [ {...} ] }
                    # plan_json é geralmente uma lista com um dict
                    if isinstance(plan_json, list) and len(plan_json) > 0:
                        plan = plan_json[0]
                    else:
                        plan = plan_json
                    exec_time = plan.get('Execution Time') or plan.get('Plan', {}).get('Execution Time')
                exec_times.append(exec_time)

            exec_times_clean = [t for t in exec_times if t is not None]
            median_exec = statistics.median(exec_times_clean) if exec_times_clean else None

            results.append({
                'size_index': size,
                'bytes_raw': bytes_raw,
                'bytes_stored': bytes_stored,
                'level': level,
                'operator': op_name,
                'execution_time_ms_median': median_exec,
                'runs': N_RUNS
            })
            print(f"size={size} lvl={level} op={op_name} median_ms={median_exec} raw_bytes={bytes_raw} stored={bytes_stored}")

    # Save CSV
    fieldnames = ['size_index','bytes_raw','bytes_stored','level','operator','execution_time_ms_median','runs']
    with open(OUT_CSV, 'w', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(results)

    cur.close()
    conn.close()
    print("Saved", OUT_CSV)

if __name__ == "__main__":
    main()
