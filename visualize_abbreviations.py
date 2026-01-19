#!/usr/bin/env python3
"""
Visualize unapproved abbreviation findings from medication orders
"""
import csv
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter
import pandas as pd

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 10)

# Read the data
with open('Test Results/unap_abbrev_mt_2025-01-19.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    data = list(reader)

# Prepare data for analysis
dose_flagged = []
label_flagged = []

for row in data:
    if row['FlaggedInDose']:
        meanings = [m.strip() for m in row['FlaggedInDose'].split(',')]
        dose_flagged.extend(meanings)
    if row['FlaggedInLabel']:
        meanings = [m.strip() for m in row['FlaggedInLabel'].split(',')]
        label_flagged.extend(meanings)

dose_counter = Counter(dose_flagged)
label_counter = Counter(label_flagged)

# Get top 10 categories (excluding NULL)
top_dose = [(k, v) for k, v in dose_counter.most_common(11) if k != 'NULL'][:10]
top_label = [(k, v) for k, v in label_counter.most_common(11) if k != 'NULL'][:10]

# Get all unique categories from top 10 of both
all_categories = set([k for k, v in top_dose] + [k for k, v in top_label])

# Create comparison dataframe
comparison_data = []
for cat in all_categories:
    dose_count = dose_counter.get(cat, 0)
    label_count = label_counter.get(cat, 0)
    comparison_data.append({
        'Category': cat,
        'Dose Instructions': dose_count,
        'Label Comments': label_count,
        'Total': dose_count + label_count
    })

df = pd.DataFrame(comparison_data).sort_values('Total', ascending=False).head(10)

# Create visualizations
fig = plt.figure(figsize=(16, 12))

# 1. Stacked bar chart comparing dose vs label
ax1 = plt.subplot(2, 2, 1)
x_pos = range(len(df))
width = 0.6

p1 = ax1.barh(x_pos, df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
p2 = ax1.barh(x_pos, df['Label Comments'], width, left=df['Dose Instructions'], 
              label='Label Comments', color='#3498db')

ax1.set_yticks(x_pos)
ax1.set_yticklabels(df['Category'], fontsize=9)
ax1.invert_yaxis()
ax1.set_xlabel('Frequency', fontsize=11, fontweight='bold')
ax1.set_title('Top 10 Unapproved Abbreviations by Location\n(Dose Instructions vs Label Comments)', 
              fontsize=12, fontweight='bold', pad=15)
ax1.legend(loc='lower right')
ax1.grid(axis='x', alpha=0.3)

# Add value labels
for i, (idx, row) in enumerate(df.iterrows()):
    dose = row['Dose Instructions']
    label = row['Label Comments']
    total = row['Total']
    
    # Label for dose instructions
    if dose > 0:
        ax1.text(dose/2, i, f'{int(dose)}', ha='center', va='center', 
                color='white', fontweight='bold', fontsize=8)
    
    # Label for label comments
    if label > 0:
        ax1.text(dose + label/2, i, f'{int(label)}', ha='center', va='center',
                color='white', fontweight='bold', fontsize=8)
    
    # Total at the end
    ax1.text(total + 50, i, f'{int(total)}', ha='left', va='center',
            fontweight='bold', fontsize=8)

# 2. Percentage comparison
ax2 = plt.subplot(2, 2, 2)
df['Dose_Pct'] = (df['Dose Instructions'] / df['Total'] * 100).round(1)
df['Label_Pct'] = (df['Label Comments'] / df['Total'] * 100).round(1)

x_pos = range(len(df))
p1 = ax2.barh(x_pos, df['Dose_Pct'], width, label='Dose Instructions', color='#e74c3c')
p2 = ax2.barh(x_pos, df['Label_Pct'], width, left=df['Dose_Pct'],
              label='Label Comments', color='#3498db')

ax2.set_yticks(x_pos)
ax2.set_yticklabels(df['Category'], fontsize=9)
ax2.invert_yaxis()
ax2.set_xlabel('Percentage (%)', fontsize=11, fontweight='bold')
ax2.set_xlim(0, 100)
ax2.set_title('Distribution Within Each Category\n(% in Dose Instructions vs Label Comments)',
              fontsize=12, fontweight='bold', pad=15)
ax2.legend(loc='lower right')
ax2.grid(axis='x', alpha=0.3)

# Add percentage labels
for i, (idx, row) in enumerate(df.iterrows()):
    dose_pct = row['Dose_Pct']
    label_pct = row['Label_Pct']
    
    if dose_pct > 5:
        ax2.text(dose_pct/2, i, f'{dose_pct:.0f}%', ha='center', va='center',
                color='white', fontweight='bold', fontsize=8)
    
    if label_pct > 5:
        ax2.text(dose_pct + label_pct/2, i, f'{label_pct:.0f}%', ha='center', va='center',
                color='white', fontweight='bold', fontsize=8)

# 3. Top abbreviations in dose instructions only
ax3 = plt.subplot(2, 2, 3)
top_10_dose = df.nlargest(10, 'Dose Instructions')
colors_dose = plt.cm.Reds(range(len(top_10_dose), 0, -1))
bars = ax3.barh(range(len(top_10_dose)), top_10_dose['Dose Instructions'], color=colors_dose)

ax3.set_yticks(range(len(top_10_dose)))
ax3.set_yticklabels(top_10_dose['Category'], fontsize=9)
ax3.invert_yaxis()
ax3.set_xlabel('Frequency', fontsize=11, fontweight='bold')
ax3.set_title('Top 10 in Dose Instructions', fontsize=12, fontweight='bold', pad=15)
ax3.grid(axis='x', alpha=0.3)

for i, (idx, row) in enumerate(top_10_dose.iterrows()):
    count = row['Dose Instructions']
    ax3.text(count + 50, i, f'{int(count)}', ha='left', va='center',
            fontweight='bold', fontsize=9)

# 4. Top abbreviations in label comments only
ax4 = plt.subplot(2, 2, 4)
top_10_label = df.nlargest(10, 'Label Comments')
colors_label = plt.cm.Blues(range(len(top_10_label), 0, -1))
bars = ax4.barh(range(len(top_10_label)), top_10_label['Label Comments'], color=colors_label)

ax4.set_yticks(range(len(top_10_label)))
ax4.set_yticklabels(top_10_label['Category'], fontsize=9)
ax4.invert_yaxis()
ax4.set_xlabel('Frequency', fontsize=11, fontweight='bold')
ax4.set_title('Top 10 in Label Comments', fontsize=12, fontweight='bold', pad=15)
ax4.grid(axis='x', alpha=0.3)

for i, (idx, row) in enumerate(top_10_label.iterrows()):
    count = row['Label Comments']
    ax4.text(count + 20, i, f'{int(count)}', ha='left', va='center',
            fontweight='bold', fontsize=9)

plt.tight_layout()
plt.savefig('Test Results/unapproved_abbreviations_analysis.png', dpi=300, bbox_inches='tight')
print("Visualization saved to: Test Results/unapproved_abbreviations_analysis.png")

# Create summary statistics
print("\n" + "="*80)
print("UNAPPROVED ABBREVIATION ANALYSIS SUMMARY")
print("="*80)
print(f"\nTotal orders with unapproved abbreviations: {len(data):,}")
print(f"Total unapproved abbreviation instances in dose instructions: {sum(dose_counter.values()):,}")
print(f"Total unapproved abbreviation instances in label comments: {sum(label_counter.values()):,}")

print("\n" + "-"*80)
print("TOP 10 CATEGORIES:")
print("-"*80)
print(f"{'Category':<40} {'Dose':>10} {'Label':>10} {'Total':>10} {'% Dose':>8}")
print("-"*80)
for _, row in df.iterrows():
    print(f"{row['Category']:<40} {int(row['Dose Instructions']):>10,} "
          f"{int(row['Label Comments']):>10,} {int(row['Total']):>10,} "
          f"{row['Dose_Pct']:>7.1f}%")
print("="*80)
