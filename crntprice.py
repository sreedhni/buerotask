import requests
import pandas as pd
import csv

def flatten_json(json_data, parent_key='', sep='_'):
    flattened = {}
    for k, v in json_data.items():
        new_key = f"{parent_key}{sep}{k}" if parent_key else k
        if isinstance(v, dict):
            flattened.update(flatten_json(v, new_key, sep=sep))
        else:
            flattened[new_key] = v
    return flattened

def fetch_and_process_data(api_url):
    response = requests.get(api_url)
    
    if response.status_code == 200:
        data = response.json()['bpi']['USD']
        flattened_data = flatten_json(data)
        
        df = pd.DataFrame([flattened_data])
        
        df.to_csv('bitcoin_data.csv', index=False)
        
        return df
    else:
        print(f"Error: Unable to fetch data. Status Code: {response.status_code}")
        return None

api_url = 'https://api.coindesk.com/v1/bpi/currentprice.json'

bitcoin_data = fetch_and_process_data(api_url)

if bitcoin_data is not None:
    print("Dataframe:")
    print(bitcoin_data)
