import pandas as pd

# Enterprise structure definition
enterprise_structure = {
    'Countries': [
        {'Name': 'Canada', 'Description': 'Canada Branch'},
        {'Name': 'France', 'Description': 'France Branch'},
        {'Name': 'USA', 'Description': 'USA Headquarters'},
        {'Name': 'Germany', 'Description': 'Germany Branch'},
        {'Name': 'UK', 'Description': 'United Kingdom Branch'},
        {'Name': 'UAE', 'Description': 'United Arab Emirates Branch'},
        {'Name': 'Qatar', 'Description': 'Qatar Branch'},
        {'Name': 'China', 'Description': 'China Branch'},
        {'Name': 'Spain', 'Description': 'Spain Branch'}
    ],
    'Cities': [
        {'Country': 'Canada', 'Name': 'Toronto', 'Description': 'Toronto Office'},
        {'Country': 'Canada', 'Name': 'Vancouver', 'Description': 'Vancouver Office'},
        {'Country': 'France', 'Name': 'Paris', 'Description': 'Paris Office'},
        {'Country': 'France', 'Name': 'Lyon', 'Description': 'Lyon Office'},
        {'Country': 'USA', 'Name': 'New York HQ', 'Description': 'New York Headquarters'},
        {'Country': 'USA', 'Name': 'Chicago', 'Description': 'Chicago Office'},
        {'Country': 'Germany', 'Name': 'Frankfurt', 'Description': 'Frankfurt Office'},
        {'Country': 'Germany', 'Name': 'Berlin', 'Description': 'Berlin Office'},
        {'Country': 'UK', 'Name': 'London Branch', 'Description': 'London Office'},
        {'Country': 'UAE', 'Name': 'Dubai', 'Description': 'Dubai Office'},
        {'Country': 'Qatar', 'Name': 'Doha', 'Description': 'Doha Office'},
        {'Country': 'China', 'Name': 'Hong Kong', 'Description': 'Hong Kong Office'},
        {'Country': 'Spain', 'Name': 'Madrid', 'Description': 'Madrid Office'}
    ],
    'Departments': [
        'Trading', 'Compliance', 'IT', 'HR', 'Operations', 'Finance', 'Legal',
        'Marketing', 'Customer Service', 'Treasury Management', 'Business Banking', 'Investment Banking'
    ]
}

base_dn = "DC=itpositive,DC=com"
enterprise_root = "Enterprise"

# Generate OU data
ous_data = []

# Create Enterprise Root OU entry (for reference, though PowerShell script creates it)
ous_data.append({
    'Type': 'Enterprise',
    'Name': enterprise_root,
    'ParentPath': base_dn,
    'Description': 'Enterprise Root Organization Unit'
})

# Create Country OUs under Enterprise
for country in enterprise_structure['Countries']:
    ous_data.append({
        'Type': 'Country',
        'Name': country['Name'],
        'ParentPath': f"OU={enterprise_root},{base_dn}",  # ← FIXED: Under Enterprise OU!
        'Description': country['Description']
    })

# Create City OUs under Country
for city in enterprise_structure['Cities']:
    country_ou_path = f"OU={city['Country']},OU={enterprise_root},{base_dn}"  # ← FIXED: Under Enterprise!
    ous_data.append({
        'Type': 'City',
        'Name': city['Name'],
        'ParentPath': country_ou_path,
        'Description': city['Description']
    })

# Create Department OUs under City
for city in enterprise_structure['Cities']:
    city_ou_path = f"OU={city['Name']},OU={city['Country']},OU={enterprise_root},{base_dn}"  # ← FIXED: Under Enterprise!
    for dept in enterprise_structure['Departments']:
        ous_data.append({
            'Type': 'Department',
            'Name': dept,
            'ParentPath': city_ou_path,
            'Description': f"{dept} Department in {city['Name']}"
        })

# Create DataFrame and save CSV
df_ous = pd.DataFrame(ous_data)
df_ous.to_csv('enterprise_ous.csv', index=False)
print("CSV 'enterprise_ous.csv' generated successfully!")
print(f"Created {len(ous_data)} OU entries")

# Preview the data
print("\nFirst 10 OU entries:")
print(df_ous.head(10).to_string(index=False))
