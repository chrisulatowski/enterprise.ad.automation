import pandas as pd
from faker import Faker
import random

# Initialize Faker
fake = Faker()

# Enterprise-style structure with country-city mapping
country_branch_map = {
    'USA': ['New York HQ'],
    'UK': ['London Branch'],
    'Germany': ['Frankfurt'],
    'France': ['Paris'],
    'Canada': ['Toronto'],
    'UAE': ['Dubai'],
    'Qatar': ['Doha'],
    'China': ['Hong Kong'],
    'Spain': ['Madrid']
}
departments = [
    'Trading', 'Compliance', 'IT', 'HR', 'Operations', 'Finance', 'Legal',
    'Marketing', 'Customer Service', 'Treasury Management', 'Business Banking', 'Investment Banking'
]

users = []
for i in range(10):  # Small CSV for testing
    first = fake.first_name()
    last = fake.last_name()
    uname = first[0].lower() + last.lower()
    country = random.choice(list(country_branch_map.keys()))
    branch = random.choice(country_branch_map[country])
    dept = random.choice(departments)
    ou = f"OU={dept},OU={branch},DC=itpositive,DC=com"
    users.append({
        'Name': uname,  # Added for New-ADUser
        'UserPrincipalName': f'{uname}@itpositive.com',
        'SamAccountName': uname,
        'FirstName': first,
        'LastName': last,
        'DisplayName': f'{first} {last}',
        'Department': dept,
        'Title': 'Employee',
        'Country': country,
        'Branch': branch,
        'OU': ou,
        'Manager': '',
        'Email': f'{uname}@itpositive.com',
        'EmployeeID': 10000 + i,
        'PhoneNumber': fake.phone_number(),
        'AccountEnabled': True,
        'Password': 'TempPass123!',
        'Groups': dept + 'Team',
        'MFAEnabled': random.choice([True, False]),
        'GPOPolicyApplied': 'DefaultPolicy',
        'LastLogonDate': pd.Timestamp.today().date(),
        'PasswordLastSet': pd.Timestamp.today().date(),
        'AccountLocked': False,
        'Notes': ''
    })

# Create DataFrame and save CSV
df_full = pd.DataFrame(users)
df_full.to_csv('enterprise_users.csv', index=False)
print("CSV 'enterprise_users.csv' generated successfully!")
