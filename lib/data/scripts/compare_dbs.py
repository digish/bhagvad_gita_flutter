import sqlite3
import os

DB_V2 = "assets/database/geeta_v2.db"
DB_V4 = "assets/database/geeta_v4.db"

def compare_tables(conn1, conn2, table_name, pk_col):
    cursor1 = conn1.cursor()
    cursor2 = conn2.cursor()
    
    # Check if table exists
    cursor1.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'")
    if not cursor1.fetchone():
        print(f"Table '{table_name}' does not exist in V2.")
        return
        
    cursor2.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table_name}'")
    if not cursor2.fetchone():
        print(f"Table '{table_name}' does not exist in V4.")
        return

    print(f"\n--- Comparing table: {table_name} ---")
    
    # Fetch all data as dict {pk: row}
    # For composite PKs or no PK, assume the first few cols are unique identifiers or handle 'rowid'
    
    cursor1.execute(f"PRAGMA table_info({table_name})")
    cols1 = [row[1] for row in cursor1.fetchall()]
    
    cursor2.execute(f"PRAGMA table_info({table_name})")
    cols2 = [row[1] for row in cursor2.fetchall()]
    
    # Compare common columns
    common_cols = list(set(cols1) & set(cols2))
    common_cols.sort()
    
    if len(common_cols) != len(cols1) or len(common_cols) != len(cols2):
        print(f"  [NOTE] Schema mismatch in {table_name}. Comparing common columns: {common_cols}")
        
    # Build query for common columns
    cols_str = ", ".join(common_cols)
    query = f"SELECT {cols_str} FROM {table_name}"
    
    cursor1.execute(query)
    rows1 = cursor1.fetchall()
    dict1 = {}
    
    # Key generation logic needs to identify key columns within common_cols
    # master_shlokas: 'id'
    # shloka_scripts: 'shloka_id', 'script_code'
    # translations: 'shloka_id', 'language_code', 'author'
    # commentaries: 'shloka_id', 'author_name', 'language_code'
    
    # Map column names to indices in rows
    col_map = {name: i for i, name in enumerate(common_cols)}
    
    def get_key(row, table):
        if table == 'master_shlokas':
            return row[col_map['id']]
        elif table == 'shloka_scripts':
            return (row[col_map['shloka_id']], row[col_map['script_code']])
        elif table == 'translations':
            return (row[col_map['shloka_id']], row[col_map['language_code']], row[col_map['author']])
        elif table == 'commentaries':
            return (row[col_map['shloka_id']], row[col_map['author_name']], row[col_map['language_code']])
        return row[0]

    for row in rows1:
        key = get_key(row, table_name)
        dict1[key] = row
        
    cursor2.execute(query)
    rows2 = cursor2.fetchall()
    dict2 = {}
    
    for row in rows2:
        key = get_key(row, table_name)
        dict2[key] = row

    # Comparison
    keys1 = set(dict1.keys())
    keys2 = set(dict2.keys())
    
    added = keys2 - keys1
    removed = keys1 - keys2
    common = keys1 & keys2
    
    modified = []
    
    for key in common:
        row1 = dict1[key]
        row2 = dict2[key]
        
        if table_name == 'commentaries':
             # Skip 'id' comparison since it's auto-increment and might vary
             # Use col_map to exclude 'id'
            r1_vals = [val for i, val in enumerate(row1) if common_cols[i] != 'id']
            r2_vals = [val for i, val in enumerate(row2) if common_cols[i] != 'id']
            if r1_vals != r2_vals:
                modified.append(key)
        else:
            if row1 != row2:
                modified.append(key)

    print(f"Total rows in V2: {len(keys1)}")
    print(f"Total rows in V4: {len(keys2)}")
    print(f"Added: {len(added)}")
    print(f"Removed: {len(removed)}")
    print(f"Modified: {len(modified)}")

def compare_search_index(conn1, conn2):
    print(f"\n--- Comparing table: search_index ---")
    
    # Since search_index has no PK and might contain duplicates or varying order,
    # we group by all columns and count occurrences.
    # We filter out Chapter 13 to see if other chapters are affected.
    
    query = """
    SELECT term_original, term_romanized, ref_id, display_text, language_code, category, COUNT(*) as cnt
    FROM search_index
    WHERE ref_id NOT LIKE '13.%'
    GROUP BY term_original, term_romanized, ref_id, display_text, language_code, category
    """
    
    cursor1 = conn1.cursor()
    cursor1.execute(query)
    rows1 = cursor1.fetchall() # List of tuples
    
    cursor2 = conn2.cursor() 
    cursor2.execute(query)
    rows2 = cursor2.fetchall()
    
    set1 = set(rows1)
    set2 = set(rows2)
    
    diff1 = set1 - set2
    diff2 = set2 - set1
    
    if not diff1 and not diff2:
        print(">> Non-Chapter-13 indices are IDENTICAL. <<")
    else:
        print(f">> WARNING: Differences found in non-Chapter-13 indices! <<")
        print(f"V2 unique entries: {len(diff1)}")
        print(f"V4 unique entries: {len(diff2)}")
        if len(diff1) < 10: print(f"Sample V2 unique: {list(diff1)}")
        if len(diff2) < 10: print(f"Sample V4 unique: {list(diff2)}")

    # Check Chapter 13 counts
    q_ch13 = "SELECT COUNT(*) FROM search_index WHERE ref_id LIKE '13.%'"
    c1 = cursor1.execute(q_ch13).fetchone()[0]
    c2 = cursor2.execute(q_ch13).fetchone()[0]
    print(f"Chapter 13 Index Rows: V2={c1}, V4={c2}")

def main():
    if not os.path.exists(DB_V2):
        print(f"Error: {DB_V2} not found.")
        return
    if not os.path.exists(DB_V4):
        print(f"Error: {DB_V4} not found.")
        return
        
    conn1 = sqlite3.connect(DB_V2)
    conn2 = sqlite3.connect(DB_V4)
    
    try:
        compare_tables(conn1, conn2, 'master_shlokas', 'id')
        compare_tables(conn1, conn2, 'shloka_scripts', 'composite')
        compare_tables(conn1, conn2, 'translations', 'composite')
        compare_tables(conn1, conn2, 'commentaries', 'composite_unique')
        compare_search_index(conn1, conn2)
        
    finally:
        conn1.close()
        conn2.close()

if __name__ == "__main__":
    main()
