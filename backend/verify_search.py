import requests

def test_search(query):
    url = 'http://127.0.0.1:8000/api/projects/'
    print(f"Testing search with query: '{query}'")
    try:
        response = requests.get(url, params={'search': query})
        if response.status_code == 200:
            results = response.json()
            print(f"Found {len(results)} projects.")
            for p in results:
                print(f" - ID: {p['id']}, Address: {p['address']}, Intercom: {p.get('intercom_code')}, Client: {p.get('client_info')}")
        else:
            print(f"Error: {response.status_code}")
    except Exception as e:
        print(f"Exception: {e}")
    print("-" * 30)

if __name__ == "__main__":
    # Test cases based on potentially existing data
    test_search('Вячеслав') # Should find ID 1
    test_search('213424') # Should find ID 1 (Intercom)
    test_search('nowiy') # Should find ID 23 (Address)
    test_search('NonExistentString') # Should return 0
