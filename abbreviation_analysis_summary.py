#!/usr/bin/env python3
"""
Generate comprehensive text-based analysis of unapproved abbreviations
"""
import csv
from collections import Counter

# Read the data
with open('Test Results/unap_abbrev_mt_2025-01-19.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    data = list(reader)

# Prepare data for analysis
dose_flagged = []
label_flagged = []
all_flagged = []

for row in data:
    if row['Flagged']:
        meanings = [m.strip() for m in row['Flagged'].split(',')]
        all_flagged.extend(meanings)
    if row['FlaggedInDose']:
        meanings = [m.strip() for m in row['FlaggedInDose'].split(',')]
        dose_flagged.extend(meanings)
    if row['FlaggedInLabel']:
        meanings = [m.strip() for m in row['FlaggedInLabel'].split(',')]
        label_flagged.extend(meanings)

all_counter = Counter(all_flagged)
dose_counter = Counter(dose_flagged)
label_counter = Counter(label_flagged)

# Remove NULL entries for cleaner reporting
dose_counter.pop('NULL', None)
label_counter.pop('NULL', None)

# Get combined categories
all_categories = sorted(set(list(dose_counter.keys()) + list(label_counter.keys())))

# Calculate statistics
total_records = len(data)
total_dose_instances = sum(dose_counter.values())
total_label_instances = sum(label_counter.values())
total_all_instances = total_dose_instances + total_label_instances

print("=" * 90)
print("UNAPPROVED ABBREVIATION ANALYSIS SUMMARY")
print("Data Source: Test Results/unap_abbrev_mt_2025-01-19.csv")
print("=" * 90)

print("\n" + "─" * 90)
print("OVERALL STATISTICS")
print("─" * 90)
print(f"  Total medication orders flagged:              {total_records:>10,}")
print(f"  Total instances in Dose Instructions:         {total_dose_instances:>10,}")
print(f"  Total instances in Label Comments:            {total_label_instances:>10,}")
print(f"  Total instances (combined):                   {total_all_instances:>10,}")
print(f"  Average instances per order:                  {total_all_instances/total_records:>10.2f}")

dose_pct = (total_dose_instances / total_all_instances * 100) if total_all_instances > 0 else 0
label_pct = (total_label_instances / total_all_instances * 100) if total_all_instances > 0 else 0

print(f"\n  Distribution:")
print(f"    - Dose Instructions:                        {dose_pct:>9.1f}%")
print(f"    - Label Comments:                           {label_pct:>9.1f}%")

# TOP 15 OVERALL
print("\n\n" + "=" * 90)
print("TOP 15 UNAPPROVED ABBREVIATIONS (OVERALL)")
print("=" * 90)
print(f"{'Rank':<6} {'Abbreviation':<45} {'Count':>12} {'% of Total':>10}")
print("─" * 90)

for rank, (abbrev, count) in enumerate(all_counter.most_common(15), 1):
    pct = (count / total_all_instances * 100) if total_all_instances > 0 else 0
    print(f"{rank:<6} {abbrev:<45} {count:>12,} {pct:>9.1f}%")

# DETAILED BREAKDOWN
print("\n\n" + "=" * 90)
print("DETAILED BREAKDOWN BY CATEGORY (All Categories)")
print("=" * 90)
print(f"{'Abbreviation':<45} {'Dose':>10} {'Label':>10} {'Total':>10} {'% Dose':>8} {'% Label':>8}")
print("─" * 90)

# Combine and sort by total
category_data = []
for cat in all_categories:
    dose_count = dose_counter.get(cat, 0)
    label_count = label_counter.get(cat, 0)
    total = dose_count + label_count
    category_data.append((cat, dose_count, label_count, total))

category_data.sort(key=lambda x: x[3], reverse=True)

for abbrev, dose_count, label_count, total in category_data:
    dose_pct = (dose_count / total * 100) if total > 0 else 0
    label_pct = (label_count / total * 100) if total > 0 else 0
    print(f"{abbrev:<45} {dose_count:>10,} {label_count:>10,} {total:>10,} "
          f"{dose_pct:>7.1f}% {label_pct:>7.1f}%")

# TOP IN DOSE INSTRUCTIONS
print("\n\n" + "=" * 90)
print("TOP 15 IN DOSE INSTRUCTIONS")
print("=" * 90)
print(f"{'Rank':<6} {'Abbreviation':<45} {'Count':>12} {'% of Dose':>12}")
print("─" * 90)

for rank, (abbrev, count) in enumerate(dose_counter.most_common(15), 1):
    pct = (count / total_dose_instances * 100) if total_dose_instances > 0 else 0
    print(f"{rank:<6} {abbrev:<45} {count:>12,} {pct:>11.1f}%")

# TOP IN LABEL COMMENTS
print("\n\n" + "=" * 90)
print("TOP 15 IN LABEL COMMENTS")
print("=" * 90)
print(f"{'Rank':<6} {'Abbreviation':<45} {'Count':>12} {'% of Label':>12}")
print("─" * 90)

for rank, (abbrev, count) in enumerate(label_counter.most_common(15), 1):
    pct = (count / total_label_instances * 100) if total_label_instances > 0 else 0
    print(f"{rank:<6} {abbrev:<45} {count:>12,} {pct:>11.1f}%")

# KEY INSIGHTS
print("\n\n" + "=" * 90)
print("KEY INSIGHTS")
print("=" * 90)

top_3 = all_counter.most_common(3)
print("\n1. TOP 3 MOST COMMON ABBREVIATIONS:")
for rank, (abbrev, count) in enumerate(top_3, 1):
    pct = (count / total_all_instances * 100)
    print(f"   {rank}. {abbrev}: {count:,} instances ({pct:.1f}% of all)")

print("\n2. LOCATION PREFERENCE:")
dose_heavy = [(cat, dose_counter[cat], label_counter.get(cat, 0)) 
              for cat in dose_counter.keys() 
              if dose_counter[cat] > 0 and (dose_counter[cat] / (dose_counter[cat] + label_counter.get(cat, 0))) > 0.8]
dose_heavy.sort(key=lambda x: x[1], reverse=True)

if dose_heavy:
    print("   Categories predominantly in Dose Instructions (>80%):")
    for cat, dose_count, label_count in dose_heavy[:5]:
        total = dose_count + label_count
        pct = (dose_count / total * 100)
        print(f"   - {cat}: {dose_count:,} ({pct:.1f}% in dose)")

label_heavy = [(cat, label_counter[cat], dose_counter.get(cat, 0)) 
               for cat in label_counter.keys() 
               if label_counter[cat] > 0 and (label_counter[cat] / (label_counter[cat] + dose_counter.get(cat, 0))) > 0.8]
label_heavy.sort(key=lambda x: x[1], reverse=True)

if label_heavy:
    print("\n   Categories predominantly in Label Comments (>80%):")
    for cat, label_count, dose_count in label_heavy[:5]:
        total = label_count + dose_count
        pct = (label_count / total * 100)
        print(f"   - {cat}: {label_count:,} ({pct:.1f}% in label)")

print("\n3. DISTRIBUTION INSIGHT:")
print(f"   - {dose_pct:.1f}% of all instances appear in Dose Instructions")
print(f"   - {label_pct:.1f}% of all instances appear in Label Comments")

print("\n" + "=" * 90)
print("END OF REPORT")
print("=" * 90)
