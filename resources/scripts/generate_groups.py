import pandas as pd

# Departments and cities for group creation
departments = [
    'Trading', 'Compliance', 'IT', 'HR', 'Operations', 'Finance', 'Legal',
    'Marketing', 'Customer Service', 'Treasury Management', 'Business Banking', 'Investment Banking'
]

cities = [
    {'Country': 'Canada', 'Name': 'Toronto'},
    {'Country': 'Canada', 'Name': 'Vancouver'},
    {'Country': 'France', 'Name': 'Paris'},
    {'Country': 'France', 'Name': 'Lyon'},
    {'Country': 'USA', 'Name': 'New York HQ'},
    {'Country': 'USA', 'Name': 'Chicago'},
    {'Country': 'Germany', 'Name': 'Frankfurt'},
    {'Country': 'Germany', 'Name': 'Berlin'},
    {'Country': 'UK', 'Name': 'London Branch'},
    {'Country': 'UAE', 'Name': 'Dubai'},
    {'Country': 'Qatar', 'Name': 'Doha'},
    {'Country': 'China', 'Name': 'Hong Kong'},
    {'Country': 'Spain', 'Name': 'Madrid'}
]

base_dn = "DC=itpositive,DC=com"
enterprise_ou = "Enterprise"  # ← ADD THIS

# Generate Groups data
groups_data = []

for city in cities:
    for dept in departments:
        # Create city-department format groups
        group_name = f"{city['Name']}-{dept}"
        sam_account_name = f"{city['Name'].lower().replace(' ', '-')}-{dept.lower().replace(' ', '-')}"
        email = f"{sam_account_name}@itpositive.com"
        # ← FIX THE OU PATH TO INCLUDE ENTERPRISE
        ou_path = f"OU={dept},OU={city['Name']},OU={city['Country']},OU={enterprise_ou},{base_dn}"
        description = f"{dept} team for {city['Name']}"

        groups_data.append({
            'Name': group_name,
            'SamAccountName': sam_account_name,
            'GroupCategory': 'Security',
            'GroupScope': 'Global',
            'Description': description,
            'OU': ou_path,
            'Email': email
        })

# Create DataFrame and save CSV
df_groups = pd.DataFrame(groups_data)
df_groups.to_csv('enterprise_groups.csv', index=False)
print("CSV 'enterprise_groups.csv' generated successfully!")
print(f"Created {len(groups_data)} group entries")

# Preview the data
print("\nFirst 10 Group entries:")
print(df_groups.head(10).to_string(index=False))
