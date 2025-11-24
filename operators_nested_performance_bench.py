import psycopg2
import csv

# Database connection
conn = psycopg2.connect(
    host="localhost",
    port=5432,
    database="exercises",
    user="postgres",
    password="postgres"
)
cur = conn.cursor()

# Operators to test
operators = [
    ("arrow", "jb -> 'obj' -> 'obj' -> 'obj' -> 'obj' -> 'key'"),
    ("path", "jb #> '{obj,obj,obj,obj,key}'"),
    ("subscript", "jb['obj']['obj']['obj']['obj']['key']"),
    ("jsonpath", "jsonb_path_query_first(jb, '$.obj.obj.obj.obj.key')")
]

# Results storage
results = []

for size in range(120):
    for level in range(10):
        for op_name, op_query in operators:
            query = f"""
            EXPLAIN (ANALYZE, BUFFERS, FORMAT JSON)
            SELECT {op_query}
            FROM test_jsonb_nesting
            WHERE size = {size} AND level = {level};
            """
            
            cur.execute(query)
            plan = cur.fetchone()[0][0]
            
            exec_time = plan['Execution Time']
            planning_time = plan['Planning Time']
            
            results.append({
                'size': size,
                'level': level,
                'operator': op_name,
                'execution_time': exec_time,
                'planning_time': planning_time
            })
            
            print(f"Size: {size}, Level: {level}, Op: {op_name}, Time: {exec_time:.3f}ms")

# Save results to CSV
with open('jsonb_performance_results.csv', 'w', newline='') as f:
    writer = csv.DictWriter(f, fieldnames=['size', 'level', 'operator', 'execution_time', 'planning_time'])
    writer.writeheader()
    writer.writerows(results)

cur.close()
conn.close()
print("Results saved to jsonb_performance_results.csv")