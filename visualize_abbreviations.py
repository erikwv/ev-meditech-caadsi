#!/usr/bin/env python3
"""
Visualize unapproved abbreviation findings from medication orders
"""
import csv
import matplotlib.pyplot as plt
import seaborn as sns
from collections import Counter
import pandas as pd
import math
import os

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (14, 10)

# Create directory for individual site charts
os.makedirs('Test Results/individual_sites', exist_ok=True)

# Read the flagged orders data (updated with corrected AS pattern filtering)
with open('Test Results/unap_abbrev_mt_2025-01-19_2025-01-29_update.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    data = list(reader)

# Read the ACCURATE total order counts (ALL orders, not just flagged)
with open('Test Results/total_num_orders_by_system.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    system_counts = {row['System']: int(row['TotalOrders']) for row in reader}

with open('Test Results/total_num_orders_by_site.csv', 'r', encoding='utf-8-sig') as f:
    reader = csv.DictReader(f)
    site_counts_list = list(reader)
    site_counts = {(row['Site'], row['System']): int(row['TotalOrders']) for row in site_counts_list}

# Prepare data for analysis - split by system (EX=MC, CS=CS)
dose_flagged = []
label_flagged = []
dose_flagged_mc = []  # System = EX (MC)
label_flagged_mc = []
dose_flagged_cs = []  # System = CS
label_flagged_cs = []

# Track order counts for percentage calculations
total_orders = len(data)
mc_orders = 0
cs_orders = 0
site_orders = {}  # {site: count}

# Also track by site for each system
mc_sites = {}  # {site: {'dose': Counter, 'label': Counter, 'orders': set}}
cs_sites = {}  # {site: {'dose': Counter, 'label': Counter, 'orders': set}}

# Track unique order identifiers per system/site
mc_order_ids = set()
cs_order_ids = set()

for idx, row in enumerate(data):
    site = row['Site']
    system = row['System']
    order_id = f"{site}_{system}_{idx}"  # Create unique order identifier
    
    # Count orders by system and site
    if system == 'EX':
        mc_order_ids.add(order_id)
        if site not in mc_sites:
            mc_sites[site] = {'dose': Counter(), 'label': Counter(), 'orders': set()}
        mc_sites[site]['orders'].add(order_id)
    elif system == 'CS':
        cs_order_ids.add(order_id)
        if site not in cs_sites:
            cs_sites[site] = {'dose': Counter(), 'label': Counter(), 'orders': set()}
        cs_sites[site]['orders'].add(order_id)
    
    # Overall data
    if row['FlaggedInDose']:
        meanings = [m.strip() for m in row['FlaggedInDose'].split(',')]
        dose_flagged.extend(meanings)
        
        if system == 'EX':
            dose_flagged_mc.extend(meanings)
            mc_sites[site]['dose'].update(meanings)
        elif system == 'CS':
            dose_flagged_cs.extend(meanings)
            cs_sites[site]['dose'].update(meanings)
    
    if row['FlaggedInLabel']:
        meanings = [m.strip() for m in row['FlaggedInLabel'].split(',')]
        label_flagged.extend(meanings)
        
        if system == 'EX':
            label_flagged_mc.extend(meanings)
            mc_sites[site]['label'].update(meanings)
        elif system == 'CS':
            label_flagged_cs.extend(meanings)
            cs_sites[site]['label'].update(meanings)

# Use ACCURATE total order counts from database query results
# These include ALL orders (clean + flagged), not just the flagged ones we have in data
mc_orders = system_counts.get('EX', len(mc_order_ids))  # EX = MC system
cs_orders = system_counts.get('CS', len(cs_order_ids))  # CS system

print(f"\n{'='*70}")
print(f"ORDER COUNTS (ACCURATE - includes all orders, not just flagged):")
print(f"{'='*70}")
print(f"Total MC (EX) orders: {mc_orders:,}")
print(f"Total CS orders: {cs_orders:,}")
print(f"Grand total: {mc_orders + cs_orders:,}")
print(f"\nFlagged orders in dataset: {len(data):,}")
print(f"Flagged MC orders: {len(mc_order_ids):,}")
print(f"Flagged CS orders: {len(cs_order_ids):,}")
print(f"\nOverall flagged rate: {len(data)/(mc_orders+cs_orders)*100:.2f}%")
print(f"MC flagged rate: {len(mc_order_ids)/mc_orders*100:.2f}%")
print(f"CS flagged rate: {len(cs_order_ids)/cs_orders*100:.2f}%")
print(f"{'='*70}\n")

dose_counter = Counter(dose_flagged)
label_counter = Counter(label_flagged)
dose_counter_mc = Counter(dose_flagged_mc)
label_counter_mc = Counter(label_flagged_mc)
dose_counter_cs = Counter(dose_flagged_cs)
label_counter_cs = Counter(label_flagged_cs)

# Remove NULL entries from all counters
for counter in [dose_counter, label_counter, dose_counter_mc, label_counter_mc, dose_counter_cs, label_counter_cs]:
    counter.pop('NULL', None)

# Remove NULL from site-specific counters
for site in mc_sites:
    mc_sites[site]['dose'].pop('NULL', None)
    mc_sites[site]['label'].pop('NULL', None)

for site in cs_sites:
    cs_sites[site]['dose'].pop('NULL', None)
    cs_sites[site]['label'].pop('NULL', None)

# Get top 5 categories overall (excluding NULL)
top_dose = [(k, v) for k, v in dose_counter.most_common(5)]
top_label = [(k, v) for k, v in label_counter.most_common(5)]

# Get all unique categories from top 5 of both
all_categories = set([k for k, v in top_dose] + [k for k, v in top_label])

# Create comparison dataframe for overall (top 5)
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

df = pd.DataFrame(comparison_data).sort_values('Total', ascending=False).head(5)

# Create dataframes for MC (EX) system - top 5
mc_categories = set(list(dose_counter_mc.keys()) + list(label_counter_mc.keys()))
mc_data = []
for cat in mc_categories:
    dose_count = dose_counter_mc.get(cat, 0)
    label_count = label_counter_mc.get(cat, 0)
    mc_data.append({
        'Category': cat,
        'Dose Instructions': dose_count,
        'Label Comments': label_count,
        'Total': dose_count + label_count
    })
df_mc = pd.DataFrame(mc_data).sort_values('Total', ascending=False).head(5)

# Create dataframes for CS system - top 5
cs_categories = set(list(dose_counter_cs.keys()) + list(label_counter_cs.keys()))
cs_data = []
for cat in cs_categories:
    dose_count = dose_counter_cs.get(cat, 0)
    label_count = label_counter_cs.get(cat, 0)
    cs_data.append({
        'Category': cat,
        'Dose Instructions': dose_count,
        'Label Comments': label_count,
        'Total': dose_count + label_count
    })
df_cs = pd.DataFrame(cs_data).sort_values('Total', ascending=False).head(5)

# Create percentage-based dataframes using the same top 5
# MC System percentages
df_mc_pct = df_mc.copy()
for idx, row in df_mc_pct.iterrows():
    abbrev = row['Category']
    # Count unique orders that have this abbreviation
    orders_with_abbrev = set()
    for site in mc_sites:
        for order_id in mc_sites[site]['orders']:
            # This is simplified - we're using total counts as proxy
            pass
    # Calculate percentage of total MC orders
    total_count = row['Total']
    pct_of_orders = (total_count / mc_orders * 100) if mc_orders > 0 else 0
    df_mc_pct.at[idx, 'Pct_of_Orders'] = pct_of_orders

# CS System percentages  
df_cs_pct = df_cs.copy()
for idx, row in df_cs_pct.iterrows():
    abbrev = row['Category']
    total_count = row['Total']
    pct_of_orders = (total_count / cs_orders * 100) if cs_orders > 0 else 0
    df_cs_pct.at[idx, 'Pct_of_Orders'] = pct_of_orders

# ============================================================================
# FIGURE 1: Overall Top 5 Abbreviations
# ============================================================================
fig1 = plt.figure(figsize=(12, 8))
ax1 = plt.subplot(1, 1, 1)
x_pos = range(len(df))
width = 0.6

p1 = ax1.barh(x_pos, df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
p2 = ax1.barh(x_pos, df['Label Comments'], width, left=df['Dose Instructions'], 
              label='Label Comments', color='#3498db')

ax1.set_yticks(x_pos)
ax1.set_yticklabels(df['Category'], fontsize=11)
ax1.invert_yaxis()
ax1.set_xlabel('Frequency', fontsize=12, fontweight='bold')
ax1.set_title('Top 5 Unapproved Abbreviations (Overall)\n(Dose Instructions vs Label Comments)', 
              fontsize=14, fontweight='bold', pad=15)
ax1.legend(loc='lower right', fontsize=10)
ax1.grid(axis='x', alpha=0.3)

# Add value labels
for i, (idx, row) in enumerate(df.iterrows()):
    dose = row['Dose Instructions']
    label = row['Label Comments']
    total = row['Total']
    
    # Label for dose instructions
    if dose > 0:
        ax1.text(dose/2, i, f'{int(dose)}', ha='center', va='center', 
                color='white', fontweight='bold', fontsize=10)
    
    # Label for label comments
    if label > 0:
        ax1.text(dose + label/2, i, f'{int(label)}', ha='center', va='center',
                color='white', fontweight='bold', fontsize=10)
    
    # Total at the end
    ax1.text(total + 50, i, f'{int(total)}', ha='left', va='center',
            fontweight='bold', fontsize=10)

plt.tight_layout()
plt.savefig('Test Results/unapproved_abbreviations_top5.png', dpi=300, bbox_inches='tight')
print("Figure 1 saved: Test Results/unapproved_abbreviations_top5.png")
plt.close()

# ============================================================================
# FIGURE 2: MC (EX) System Analysis
# ============================================================================
if len(df_mc) > 0:
    # Get all MC sites sorted by volume (exclude sites with <1,000 total orders)
    mc_site_totals = {site: sum(counters['dose'].values()) + sum(counters['label'].values()) 
                      for site, counters in mc_sites.items()}
    # Filter out sites with less than 1,000 total orders
    MIN_ORDERS = 1000
    mc_site_totals_filtered = {site: total for site, total in mc_site_totals.items() 
                               if site_counts.get((site, 'EX'), 0) >= MIN_ORDERS}
    all_mc_sites = sorted(mc_site_totals_filtered.items(), key=lambda x: x[1], reverse=True)
    
    # Calculate grid layout (1 chart for system + 1 per site)
    num_mc_charts = 1 + len(all_mc_sites)
    num_cols = 3
    num_rows = math.ceil(num_mc_charts / num_cols)
    
    fig2 = plt.figure(figsize=(18, num_rows * 5))
    
    # Top 5 MC abbreviations with site breakdown
    ax1 = plt.subplot(num_rows, num_cols, 1)
    x_pos = range(len(df_mc))
    width = 0.6
    
    # Define colors for each site
    site_colors = {'RCH': '#e74c3c', 'ERH': '#3498db', 'MMH': '#2ecc71', 'FCH': '#f39c12',
                   'BH': '#9b59b6', 'SMH': '#1abc9c', 'RMH': '#e67e22', 'ARH': '#95a5a6',
                   'LMH': '#34495e', 'PAH': '#16a085', 'CGH': '#d35400', 'DH': '#c0392b',
                   'CHE': '#8e44ad', 'FLW': '#27ae60', 'CAC': '#f1c40f', 'MSA': '#e84393',
                   'QPH': '#00b894', 'HV': '#0984e3'}
    
    # Calculate site contributions for each abbreviation
    for i, (idx, row) in enumerate(df_mc.iterrows()):
        abbrev = row['Category']
        left = 0
        
        # Stack bars by site
        for site, _ in all_mc_sites:
            site_dose = mc_sites[site]['dose'].get(abbrev, 0)
            site_label = mc_sites[site]['label'].get(abbrev, 0)
            site_total = site_dose + site_label
            
            if site_total > 0:
                ax1.barh(i, site_total, width, left=left, 
                        color=site_colors.get(site, '#95a5a6'), 
                        label=site if i == 0 else '')
                left += site_total
    
    ax1.set_yticks(x_pos)
    ax1.set_yticklabels(df_mc['Category'], fontsize=9)
    ax1.invert_yaxis()
    ax1.set_xlabel('Frequency', fontsize=11, fontweight='bold')
    ax1.set_title('Top 5 Unapproved Abbreviations - MC System (EX)\n(Stacked by Site)', 
                  fontsize=12, fontweight='bold', pad=15)
    
    # Create legend with unique site labels only
    handles, labels = ax1.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax1.legend(by_label.values(), by_label.keys(), loc='lower right', fontsize=8)
    ax1.grid(axis='x', alpha=0.3)
    
    # Add total labels at the end
    for i, (idx, row) in enumerate(df_mc.iterrows()):
        total = row['Total']
        ax1.text(total + 20, i, f'{int(total)}', ha='left', va='center',
                fontweight='bold', fontsize=8)
    
    # Site-specific breakdown for ALL MC sites
    for idx, (site, total_count) in enumerate(all_mc_sites, start=2):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(mc_sites[site]['dose'].keys()) + list(mc_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = mc_sites[site]['dose'].get(abbrev, 0)
            label_count = mc_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=8)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=10, fontweight='bold')
            ax.set_title(f'MC Site: {site} (n={total_count:,})', 
                        fontsize=11, fontweight='bold', pad=10)
            ax.legend(loc='lower right', fontsize=8)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total + 5, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=7)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_mc_system.png', dpi=300, bbox_inches='tight')
    print("Figure 2 saved: Test Results/unapproved_abbreviations_mc_system.png")
    plt.close()
    
    # Save individual site charts (frequency-based)
    for site, total_count in all_mc_sites:
        fig_individual = plt.figure(figsize=(10, 6))
        ax = plt.subplot(1, 1, 1)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(mc_sites[site]['dose'].keys()) + list(mc_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = mc_sites[site]['dose'].get(abbrev, 0)
            label_count = mc_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            width = 0.6
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=10)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=12, fontweight='bold')
            ax.set_title(f'MC Site: {site} (n={total_count:,})', 
                        fontsize=14, fontweight='bold', pad=15)
            ax.legend(loc='lower right', fontsize=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total * 1.05, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=9)
            
            # Set x-axis limits to keep labels in frame
            if len(site_df) > 0:
                max_total = site_df['Total'].max()
                ax.set_xlim(0, max_total * 1.15)
            
            plt.tight_layout()
            plt.savefig(f'Test Results/individual_sites/mc_{site}_freq.png', dpi=300, bbox_inches='tight')
            plt.close()

# ============================================================================
# FIGURE 2B: MC (EX) System Analysis - PERCENTAGE OF ORDERS
# ============================================================================
if len(df_mc_pct) > 0:
    fig2b = plt.figure(figsize=(14, 8))
    ax1 = plt.subplot(1, 1, 1)
    x_pos = range(len(df_mc_pct))
    width = 0.6
    
    # Define colors for each site
    site_colors = {'RCH': '#e74c3c', 'ERH': '#3498db', 'MMH': '#2ecc71', 'FCH': '#f39c12',
                   'BH': '#9b59b6', 'SMH': '#1abc9c', 'RMH': '#e67e22', 'ARH': '#95a5a6',
                   'LMH': '#34495e', 'PAH': '#16a085', 'CGH': '#d35400', 'DH': '#c0392b',
                   'CHE': '#8e44ad', 'FLW': '#27ae60', 'CAC': '#f1c40f', 'MSA': '#e84393',
                   'QPH': '#00b894', 'HV': '#0984e3'}
    
    # Calculate site contributions as percentages
    for i, (idx, row) in enumerate(df_mc_pct.iterrows()):
        abbrev = row['Category']
        left = 0
        
        # Stack bars by site (using percentages)
        for site, _ in all_mc_sites:
            site_dose = mc_sites[site]['dose'].get(abbrev, 0)
            site_label = mc_sites[site]['label'].get(abbrev, 0)
            site_total = site_dose + site_label
            # Use ACCURATE site order count from database
            site_order_count = site_counts.get((site, 'EX'), len(mc_sites[site]['orders']))
            
            # Calculate percentage of site's orders
            site_pct = (site_total / site_order_count * 100) if site_order_count > 0 else 0
            
            if site_pct > 0:
                ax1.barh(i, site_pct, width, left=left, 
                        color=site_colors.get(site, '#95a5a6'), 
                        label=site if i == 0 else '')
                left += site_pct
    
    ax1.set_yticks(x_pos)
    ax1.set_yticklabels(df_mc_pct['Category'], fontsize=10)
    ax1.invert_yaxis()
    ax1.set_xlabel('% of Orders', fontsize=12, fontweight='bold')
    ax1.set_title(f'Top 5 Unapproved Abbreviations - MC System (EX)\n(% of {mc_orders:,} Orders - Stacked by Site)', 
                  fontsize=13, fontweight='bold', pad=15)
    
    # Create legend with unique site labels only
    handles, labels = ax1.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax1.legend(by_label.values(), by_label.keys(), loc='lower right', fontsize=9)
    ax1.grid(axis='x', alpha=0.3)
    
    # Add percentage labels at the end
    for i, (idx, row) in enumerate(df_mc_pct.iterrows()):
        pct = row['Pct_of_Orders']
        # Position label slightly to the right of the bar (relative positioning)
        ax1.text(pct * 1.05, i, f'{pct:.2f}%', ha='left', va='center',
                fontweight='bold', fontsize=9)
    
    # Set reasonable x-axis limits based on data
    max_pct = df_mc_pct['Pct_of_Orders'].max()
    ax1.set_xlim(0, max_pct * 1.15)  # 15% padding for labels
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_mc_system_pct.png', dpi=300, bbox_inches='tight')
    print("Figure 2B saved: Test Results/unapproved_abbreviations_mc_system_pct.png")
    plt.close()

# ============================================================================
# FIGURE 3: CS System Analysis
# ============================================================================
if len(df_cs) > 0:
    # Get all CS sites sorted by volume (exclude sites with <1,000 total orders)
    cs_site_totals = {site: sum(counters['dose'].values()) + sum(counters['label'].values()) 
                      for site, counters in cs_sites.items()}
    # Filter out sites with less than 1,000 total orders
    MIN_ORDERS = 1000
    cs_site_totals_filtered = {site: total for site, total in cs_site_totals.items() 
                               if site_counts.get((site, 'CS'), 0) >= MIN_ORDERS}
    all_cs_sites = sorted(cs_site_totals_filtered.items(), key=lambda x: x[1], reverse=True)
    
    # Calculate grid layout (1 chart for system + 1 per site)
    num_cs_charts = 1 + len(all_cs_sites)
    num_cols = 3
    num_rows = math.ceil(num_cs_charts / num_cols)
    
    fig3 = plt.figure(figsize=(22, num_rows * 5))
    
    # Top 5 CS abbreviations with site breakdown
    ax1 = plt.subplot(num_rows, num_cols, 1)
    x_pos = range(len(df_cs))
    width = 0.6
    
    # Use same color palette for sites
    site_colors = {'RCH': '#e74c3c', 'ERH': '#3498db', 'MMH': '#2ecc71', 'FCH': '#f39c12',
                   'BH': '#9b59b6', 'SMH': '#1abc9c', 'RMH': '#e67e22', 'ARH': '#95a5a6',
                   'LMH': '#34495e', 'PAH': '#16a085', 'CGH': '#d35400', 'DH': '#c0392b',
                   'CHE': '#8e44ad', 'FLW': '#27ae60', 'CAC': '#f1c40f', 'MSA': '#e84393',
                   'QPH': '#00b894', 'HV': '#0984e3'}
    
    # Calculate site contributions for each abbreviation
    for i, (idx, row) in enumerate(df_cs.iterrows()):
        abbrev = row['Category']
        left = 0
        
        # Stack bars by site
        for site, _ in all_cs_sites:
            site_dose = cs_sites[site]['dose'].get(abbrev, 0)
            site_label = cs_sites[site]['label'].get(abbrev, 0)
            site_total = site_dose + site_label
            
            if site_total > 0:
                ax1.barh(i, site_total, width, left=left, 
                        color=site_colors.get(site, '#95a5a6'), 
                        label=site if i == 0 else '')
                left += site_total
    
    ax1.set_yticks(x_pos)
    ax1.set_yticklabels(df_cs['Category'], fontsize=9)
    ax1.invert_yaxis()
    ax1.set_xlabel('Frequency', fontsize=11, fontweight='bold')
    ax1.set_title('Top 5 Unapproved Abbreviations - CS System\n(Stacked by Site)', 
                  fontsize=12, fontweight='bold', pad=15)
    
    # Create legend with unique site labels only
    handles, labels = ax1.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax1.legend(by_label.values(), by_label.keys(), loc='lower right', fontsize=8)
    ax1.grid(axis='x', alpha=0.3)
    
    # Add total labels at the end
    for i, (idx, row) in enumerate(df_cs.iterrows()):
        total = row['Total']
        ax1.text(total + 10, i, f'{int(total)}', ha='left', va='center',
                fontweight='bold', fontsize=8)
    
    # Site-specific breakdown for ALL CS sites
    for idx, (site, total_count) in enumerate(all_cs_sites, start=2):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(cs_sites[site]['dose'].keys()) + list(cs_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = cs_sites[site]['dose'].get(abbrev, 0)
            label_count = cs_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=8)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=10, fontweight='bold')
            ax.set_title(f'CS Site: {site} (n={total_count:,})', 
                        fontsize=11, fontweight='bold', pad=10)
            ax.legend(loc='lower right', fontsize=8)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total + 5, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=7)
    
    plt.subplots_adjust(left=0.05, right=0.98, top=0.95, bottom=0.05, hspace=0.4, wspace=0.40)
    plt.savefig('Test Results/unapproved_abbreviations_cs_system.png', dpi=300)
    print("Figure 3 saved: Test Results/unapproved_abbreviations_cs_system.png")
    plt.close()
    
    # Save individual site charts (frequency-based)
    for site, total_count in all_cs_sites:
        fig_individual = plt.figure(figsize=(10, 6))
        ax = plt.subplot(1, 1, 1)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(cs_sites[site]['dose'].keys()) + list(cs_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = cs_sites[site]['dose'].get(abbrev, 0)
            label_count = cs_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            width = 0.6
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=10)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=12, fontweight='bold')
            ax.set_title(f'CS Site: {site} (n={total_count:,})', 
                        fontsize=14, fontweight='bold', pad=15)
            ax.legend(loc='lower right', fontsize=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total * 1.05, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=9)
            
            # Set x-axis limits to keep labels in frame
            if len(site_df) > 0:
                max_total = site_df['Total'].max()
                ax.set_xlim(0, max_total * 1.15)
            
            plt.tight_layout()
            plt.savefig(f'Test Results/individual_sites/cs_{site}_freq.png', dpi=300, bbox_inches='tight')
            plt.close()

# ============================================================================
# FIGURE 3B: CS System Analysis - PERCENTAGE OF ORDERS
# ============================================================================
if len(df_cs_pct) > 0:
    fig3b = plt.figure(figsize=(14, 8))
    ax1 = plt.subplot(1, 1, 1)
    x_pos = range(len(df_cs_pct))
    width = 0.6
    
    # Use same color palette for sites
    site_colors = {'RCH': '#e74c3c', 'ERH': '#3498db', 'MMH': '#2ecc71', 'FCH': '#f39c12',
                   'BH': '#9b59b6', 'SMH': '#1abc9c', 'RMH': '#e67e22', 'ARH': '#95a5a6',
                   'LMH': '#34495e', 'PAH': '#16a085', 'CGH': '#d35400', 'DH': '#c0392b',
                   'CHE': '#8e44ad', 'FLW': '#27ae60', 'CAC': '#f1c40f', 'MSA': '#e84393',
                   'QPH': '#00b894', 'HV': '#0984e3'}
    
    # Track cumulative totals for label positioning
    bar_totals = []
    
    # Calculate site contributions as percentages
    for i, (idx, row) in enumerate(df_cs_pct.iterrows()):
        abbrev = row['Category']
        left = 0
        
        # Stack bars by site (using percentages)
        for site, _ in all_cs_sites:
            site_dose = cs_sites[site]['dose'].get(abbrev, 0)
            site_label = cs_sites[site]['label'].get(abbrev, 0)
            site_total = site_dose + site_label
            # Use ACCURATE site order count from database
            site_order_count = site_counts.get((site, 'CS'), len(cs_sites[site]['orders']))
            
            # Calculate percentage of site's orders
            site_pct = (site_total / site_order_count * 100) if site_order_count > 0 else 0
            
            if site_pct > 0:
                ax1.barh(i, site_pct, width, left=left, 
                        color=site_colors.get(site, '#95a5a6'), 
                        label=site if i == 0 else '')
                left += site_pct
        
        # Store the total stacked width for this row
        bar_totals.append(left)
    
    ax1.set_yticks(x_pos)
    ax1.set_yticklabels(df_cs_pct['Category'], fontsize=10)
    ax1.invert_yaxis()
    ax1.set_xlabel('% of Orders', fontsize=12, fontweight='bold')
    ax1.set_title(f'Top 5 Unapproved Abbreviations - CS System\n(% of {cs_orders:,} Orders - Stacked by Site)', 
                  fontsize=13, fontweight='bold', pad=15)
    
    # Create legend with unique site labels only
    handles, labels = ax1.get_legend_handles_labels()
    by_label = dict(zip(labels, handles))
    ax1.legend(by_label.values(), by_label.keys(), loc='upper right', fontsize=9)
    ax1.grid(axis='x', alpha=0.3)
    
    # Add percentage labels at the end of each stacked bar
    for i, (idx, row) in enumerate(df_cs_pct.iterrows()):
        pct = row['Pct_of_Orders']
        bar_end = bar_totals[i]  # Use the actual stacked total
        # Position label at the end of the stacked bar
        ax1.text(bar_end, i, f' {pct:.2f}%', ha='left', va='center',
                fontweight='bold', fontsize=9)
    
    # Set reasonable x-axis limits based on data - extend for legend and labels
    max_bar_total = max(bar_totals)
    ax1.set_xlim(0, max_bar_total * 1.3)  # 30% padding for labels and legend
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_cs_system_pct.png', dpi=300, bbox_inches='tight')
    print("Figure 3B saved: Test Results/unapproved_abbreviations_cs_system_pct.png")
    plt.close()

# ============================================================================
# FIGURE 4: MC Sites - Top 5 Per Site (% of TOTAL Site Orders)
# ============================================================================
if len(all_mc_sites) > 0:
    num_sites = len(all_mc_sites)
    num_cols = 2
    num_rows = math.ceil(num_sites / num_cols)
    
    fig4 = plt.figure(figsize=(16, num_rows * 5))
    
    for idx, (site, site_instance_count) in enumerate(all_mc_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(mc_sites[site]['dose'].keys()) + list(mc_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = mc_sites[site]['dose'].get(abbrev, 0)
            label_count = mc_sites[site]['label'].get(abbrev, 0)
            total_instances = dose_count + label_count
            site_data.append({
                'Category': abbrev,
                'Total': total_instances
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            # Calculate percentage of TOTAL site orders (including clean orders)
            # Use ACCURATE count from database, not just flagged orders
            site_total_orders = site_counts.get((site, 'EX'), len(mc_sites[site]['orders']))
            site_df['Pct'] = (site_df['Total'] / site_total_orders * 100)
            
            x_pos = range(len(site_df))
            width = 0.6
            bars = ax.barh(x_pos, site_df['Pct'], width, color='#e74c3c')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=9)
            ax.invert_yaxis()
            ax.set_xlabel('% of Total Site Orders', fontsize=10, fontweight='bold')
            ax.set_title(f'MC Site: {site}\n(Top 5 as % of {site_total_orders:,} Total Orders)', 
                        fontsize=11, fontweight='bold', pad=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add percentage labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                pct = row['Pct']
                ax.text(pct * 1.05, i, f'{pct:.2f}%', ha='left', va='center',
                       fontweight='bold', fontsize=8)
            
            # Set reasonable x-axis limits
            if len(site_df) > 0:
                max_pct = site_df['Pct'].max()
                ax.set_xlim(0, max_pct * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_mc_sites_top5_pct_total.png', dpi=300, bbox_inches='tight')
    print("Figure 4 saved: Test Results/unapproved_abbreviations_mc_sites_top5_pct_total.png")
    plt.close()

# ============================================================================
# FIGURE 5: CS Sites - Top 5 Per Site (% of TOTAL Site Orders)
# ============================================================================
if len(all_cs_sites) > 0:
    num_sites = len(all_cs_sites)
    num_cols = 3
    num_rows = math.ceil(num_sites / num_cols)
    
    fig5 = plt.figure(figsize=(18, num_rows * 5))
    
    for idx, (site, site_instance_count) in enumerate(all_cs_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(cs_sites[site]['dose'].keys()) + list(cs_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = cs_sites[site]['dose'].get(abbrev, 0)
            label_count = cs_sites[site]['label'].get(abbrev, 0)
            total_instances = dose_count + label_count
            site_data.append({
                'Category': abbrev,
                'Total': total_instances
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            # Calculate percentage of TOTAL site orders (including clean orders)
            # Use ACCURATE count from database, not just flagged orders
            site_total_orders = site_counts.get((site, 'CS'), len(cs_sites[site]['orders']))
            site_df['Pct'] = (site_df['Total'] / site_total_orders * 100)
            
            x_pos = range(len(site_df))
            width = 0.6
            bars = ax.barh(x_pos, site_df['Pct'], width, color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=8)
            ax.invert_yaxis()
            ax.set_xlabel('% of Total Site Orders', fontsize=9, fontweight='bold')
            ax.set_title(f'CS Site: {site}\n(Top 5 as % of {site_total_orders:,} Total Orders)', 
                        fontsize=10, fontweight='bold', pad=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add percentage labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                pct = row['Pct']
                ax.text(pct * 1.05, i, f'{pct:.2f}%', ha='left', va='center',
                       fontweight='bold', fontsize=7)
            
            # Set reasonable x-axis limits
            if len(site_df) > 0:
                max_pct = site_df['Pct'].max()
                ax.set_xlim(0, max_pct * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_cs_sites_top5_pct_total.png', dpi=300, bbox_inches='tight')
    print("Figure 5 saved: Test Results/unapproved_abbreviations_cs_sites_top5_pct_total.png")
    plt.close()

# ============================================================================
# FIGURE 6: MC Sites - Top 3 Per Site (% of TOTAL Site Orders)
# ============================================================================
if len(all_mc_sites) > 0:
    num_sites = len(all_mc_sites)
    num_cols = 2
    num_rows = math.ceil(num_sites / num_cols)
    
    fig6 = plt.figure(figsize=(16, num_rows * 4))
    
    for idx, (site, site_instance_count) in enumerate(all_mc_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 3 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(mc_sites[site]['dose'].keys()) + list(mc_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = mc_sites[site]['dose'].get(abbrev, 0)
            label_count = mc_sites[site]['label'].get(abbrev, 0)
            total_instances = dose_count + label_count
            site_data.append({
                'Category': abbrev,
                'Total': total_instances
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(3)
        
        if len(site_df) > 0:
            # Calculate percentage of TOTAL site orders (including clean orders)
            # Use ACCURATE count from database, not just flagged orders
            site_total_orders = site_counts.get((site, 'EX'), len(mc_sites[site]['orders']))
            site_df['Pct'] = (site_df['Total'] / site_total_orders * 100)
            
            x_pos = range(len(site_df))
            width = 0.6
            bars = ax.barh(x_pos, site_df['Pct'], width, color='#e74c3c')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=10)
            ax.invert_yaxis()
            ax.set_xlabel('% of Total Site Orders', fontsize=10, fontweight='bold')
            ax.set_title(f'MC Site: {site}\n(Top 3 as % of {site_total_orders:,} Total Orders)', 
                        fontsize=11, fontweight='bold', pad=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add percentage labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                pct = row['Pct']
                ax.text(pct * 1.05, i, f'{pct:.2f}%', ha='left', va='center',
                       fontweight='bold', fontsize=9)
            
            # Set reasonable x-axis limits
            if len(site_df) > 0:
                max_pct = site_df['Pct'].max()
                ax.set_xlim(0, max_pct * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_mc_sites_top3_pct_total.png', dpi=300, bbox_inches='tight')
    print("Figure 6 saved: Test Results/unapproved_abbreviations_mc_sites_top3_pct_total.png")
    plt.close()

# ============================================================================
# FIGURE 7: CS Sites - Top 3 Per Site (% of TOTAL Site Orders)
# ============================================================================
if len(all_cs_sites) > 0:
    num_sites = len(all_cs_sites)
    num_cols = 3
    num_rows = math.ceil(num_sites / num_cols)
    
    fig7 = plt.figure(figsize=(18, num_rows * 4))
    
    for idx, (site, site_instance_count) in enumerate(all_cs_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 3 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(cs_sites[site]['dose'].keys()) + list(cs_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = cs_sites[site]['dose'].get(abbrev, 0)
            label_count = cs_sites[site]['label'].get(abbrev, 0)
            total_instances = dose_count + label_count
            site_data.append({
                'Category': abbrev,
                'Total': total_instances
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(3)
        
        if len(site_df) > 0:
            # Calculate percentage of TOTAL site orders (including clean orders)
            # Use ACCURATE count from database, not just flagged orders
            site_total_orders = site_counts.get((site, 'CS'), len(cs_sites[site]['orders']))
            site_df['Pct'] = (site_df['Total'] / site_total_orders * 100)
            
            x_pos = range(len(site_df))
            width = 0.6
            bars = ax.barh(x_pos, site_df['Pct'], width, color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=9)
            ax.invert_yaxis()
            ax.set_xlabel('% of Total Site Orders', fontsize=9, fontweight='bold')
            ax.set_title(f'CS Site: {site}\n(Top 3 as % of {site_total_orders:,} Total Orders)', 
                        fontsize=10, fontweight='bold', pad=10)
            ax.grid(axis='x', alpha=0.3)
            
            # Add percentage labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                pct = row['Pct']
                ax.text(pct * 1.05, i, f'{pct:.2f}%', ha='left', va='center',
                       fontweight='bold', fontsize=8)
            
            # Set reasonable x-axis limits
            if len(site_df) > 0:
                max_pct = site_df['Pct'].max()
                ax.set_xlim(0, max_pct * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_cs_sites_top3_pct_total.png', dpi=300, bbox_inches='tight')
    print("Figure 7 saved: Test Results/unapproved_abbreviations_cs_sites_top3_pct_total.png")
    plt.close()

# ============================================================================
# FIGURE 8: MC Sites - Top 5 Per Site (BY FREQUENCY)
# ============================================================================
if len(all_mc_sites) > 0:
    num_sites = len(all_mc_sites)
    num_cols = 2
    num_rows = math.ceil(num_sites / num_cols)
    
    fig8 = plt.figure(figsize=(16, num_rows * 5))
    
    for idx, (site, site_instance_count) in enumerate(all_mc_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(mc_sites[site]['dose'].keys()) + list(mc_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = mc_sites[site]['dose'].get(abbrev, 0)
            label_count = mc_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            width = 0.6
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=9)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=10, fontweight='bold')
            site_total_orders = site_counts.get((site, 'EX'), 0)
            ax.set_title(f'MC Site: {site}\n(Top 5 by Frequency - {site_total_orders:,} Total Orders)', 
                        fontsize=11, fontweight='bold', pad=10)
            ax.legend(loc='lower right', fontsize=8)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total * 1.05, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=8)
            
            # Set x-axis limits to keep labels in frame
            if len(site_df) > 0:
                max_total = site_df['Total'].max()
                ax.set_xlim(0, max_total * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_mc_sites_top5_freq.png', dpi=300, bbox_inches='tight')
    print("Figure 8 saved: Test Results/unapproved_abbreviations_mc_sites_top5_freq.png")
    plt.close()

# ============================================================================
# FIGURE 9: CS Sites - Top 5 Per Site (BY FREQUENCY)
# ============================================================================
if len(all_cs_sites) > 0:
    num_sites = len(all_cs_sites)
    num_cols = 3
    num_rows = math.ceil(num_sites / num_cols)
    
    fig9 = plt.figure(figsize=(18, num_rows * 5))
    
    for idx, (site, site_instance_count) in enumerate(all_cs_sites, start=1):
        ax = plt.subplot(num_rows, num_cols, idx)
        
        # Get top 5 abbreviations for this site
        site_data = []
        all_abbrevs = set(list(cs_sites[site]['dose'].keys()) + list(cs_sites[site]['label'].keys()))
        for abbrev in all_abbrevs:
            dose_count = cs_sites[site]['dose'].get(abbrev, 0)
            label_count = cs_sites[site]['label'].get(abbrev, 0)
            site_data.append({
                'Category': abbrev,
                'Dose Instructions': dose_count,
                'Label Comments': label_count,
                'Total': dose_count + label_count
            })
        
        site_df = pd.DataFrame(site_data).sort_values('Total', ascending=False).head(5)
        
        if len(site_df) > 0:
            x_pos = range(len(site_df))
            width = 0.6
            p1 = ax.barh(x_pos, site_df['Dose Instructions'], width, label='Dose Instructions', color='#e74c3c')
            p2 = ax.barh(x_pos, site_df['Label Comments'], width, left=site_df['Dose Instructions'], 
                        label='Label Comments', color='#3498db')
            
            ax.set_yticks(x_pos)
            ax.set_yticklabels(site_df['Category'], fontsize=8)
            ax.invert_yaxis()
            ax.set_xlabel('Frequency', fontsize=9, fontweight='bold')
            site_total_orders = site_counts.get((site, 'CS'), 0)
            ax.set_title(f'CS Site: {site}\n(Top 5 by Frequency - {site_total_orders:,} Total Orders)', 
                        fontsize=10, fontweight='bold', pad=10)
            ax.legend(loc='lower right', fontsize=7)
            ax.grid(axis='x', alpha=0.3)
            
            # Add value labels
            for i, (idx_row, row) in enumerate(site_df.iterrows()):
                total = row['Total']
                ax.text(total * 1.05, i, f'{int(total)}', ha='left', va='center',
                       fontweight='bold', fontsize=7)
            
            # Set x-axis limits to keep labels in frame
            if len(site_df) > 0:
                max_total = site_df['Total'].max()
                ax.set_xlim(0, max_total * 1.15)
    
    plt.tight_layout()
    plt.savefig('Test Results/unapproved_abbreviations_cs_sites_top5_freq.png', dpi=300, bbox_inches='tight')
    print("Figure 9 saved: Test Results/unapproved_abbreviations_cs_sites_top5_freq.png")
    plt.close()

print("\nAll visualizations completed!")

# Create summary statistics
print("\n" + "="*80)
print("UNAPPROVED ABBREVIATION ANALYSIS SUMMARY")
print("="*80)
print(f"\nTotal orders scanned: {len(data):,}")
print(f"Total unapproved abbreviation instances in dose instructions: {sum(dose_counter.values()):,}")
print(f"Total unapproved abbreviation instances in label comments: {sum(label_counter.values()):,}")

mc_total = sum(dose_counter_mc.values()) + sum(label_counter_mc.values())
cs_total = sum(dose_counter_cs.values()) + sum(label_counter_cs.values())
print(f"\nMC (EX) System:")
print(f"  Orders: {mc_orders:,}")
print(f"  Instances: {mc_total:,}")
print(f"  % of scanned orders: {(mc_orders/total_orders*100):.1f}%")

print(f"\nCS System:")
print(f"  Orders: {cs_orders:,}")
print(f"  Instances: {cs_total:,}")
print(f"  % of scanned orders: {(cs_orders/total_orders*100):.1f}%")

print("\n" + "-"*80)
print("TOP 5 CATEGORIES (OVERALL):")
print("-"*80)
print(f"{'Category':<40} {'Dose':>10} {'Label':>10} {'Total':>10}")
print("-"*80)
for _, row in df.iterrows():
    print(f"{row['Category']:<40} {int(row['Dose Instructions']):>10,} "
          f"{int(row['Label Comments']):>10,} {int(row['Total']):>10,}")

print("\n" + "-"*80)
print("TOP 5 BY SYSTEM:")
print("-"*80)
print("\nMC (EX) System:")
for rank, (abbrev, count) in enumerate(dose_counter_mc.most_common(5) if len(dose_counter_mc) > 0 else [], 1):
    label_count = label_counter_mc.get(abbrev, 0)
    total = count + label_count
    print(f"  {rank}. {abbrev:<40} Dose: {count:>6,}  Label: {label_count:>6,}  Total: {total:>6,}")

print("\nCS System:")
for rank, (abbrev, count) in enumerate(dose_counter_cs.most_common(5) if len(dose_counter_cs) > 0 else [], 1):
    label_count = label_counter_cs.get(abbrev, 0)
    total = count + label_count
    print(f"  {rank}. {abbrev:<40} Dose: {count:>6,}  Label: {label_count:>6,}  Total: {total:>6,}")

print("\n" + "-"*80)
print("INCLUDED SITES BY VOLUME:")
print("-"*80)
print("\nMC (EX) System Sites (excluding low-volume sites):")
if mc_sites:
    excluded_sites = {'FLW', 'CHE', 'CAC', 'MSA', 'QPH'}
    mc_site_data = [(site, sum(counters['dose'].values()) + sum(counters['label'].values()), len(counters['orders'])) 
                    for site, counters in mc_sites.items() if site not in excluded_sites]
    for rank, (site, instances, orders) in enumerate(sorted(mc_site_data, key=lambda x: x[1], reverse=True), 1):
        pct_of_total = (orders / mc_orders * 100) if mc_orders > 0 else 0
        print(f"  {rank}. {site}: {orders:,} orders ({pct_of_total:.1f}% of MC), {instances:,} instances")

print("\nCS System Sites (excluding low-volume sites):")
if cs_sites:
    excluded_sites = {'FLW', 'CHE', 'CAC', 'MSA', 'QPH'}
    cs_site_data = [(site, sum(counters['dose'].values()) + sum(counters['label'].values()), len(counters['orders'])) 
                    for site, counters in cs_sites.items() if site not in excluded_sites]
    for rank, (site, instances, orders) in enumerate(sorted(cs_site_data, key=lambda x: x[1], reverse=True), 1):
        pct_of_total = (orders / cs_orders * 100) if cs_orders > 0 else 0
        print(f"  {rank}. {site}: {orders:,} orders ({pct_of_total:.1f}% of CS), {instances:,} instances")

print(f"\nExcluded sites (insufficient data): {', '.join(sorted(['FLW', 'CHE', 'CAC', 'MSA', 'QPH']))}")

print("="*80)
