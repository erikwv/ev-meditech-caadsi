#!/usr/bin/env python3
"""
Split unapproved abbreviation results by site for easier distribution.
Creates individual CSV files for each site containing only their violations.
"""
import csv
import os
from collections import defaultdict

# Input file
input_file = 'Test Results/unap_abbrev_mt_2025-01-19_2025-01-29_update.csv'

# Output directory
output_dir = 'Test Results/by_site'
os.makedirs(output_dir, exist_ok=True)

# Read the data and group by site
print(f"Reading data from {input_file}...")
with open(input_file, 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    fieldnames = reader.fieldnames
    
    # Group rows by site
    site_data = defaultdict(list)
    for row in reader:
        site = row['Site']
        site_data[site].append(row)

print(f"\nFound {len(site_data)} sites")
print(f"Total rows: {sum(len(rows) for rows in site_data.values())}")

# Write separate CSV for each site
print("\nCreating site-specific CSV files...")
for site, rows in sorted(site_data.items()):
    output_file = os.path.join(output_dir, f'{site}_violations.csv')
    
    with open(output_file, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)
    
    print(f"  {site}: {len(rows):4d} violations -> {output_file}")

print(f"\nAll site-specific CSV files saved to: {output_dir}/")
print("✓ Complete!")
