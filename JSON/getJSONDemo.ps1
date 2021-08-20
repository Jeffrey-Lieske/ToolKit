$endpointUri = "https://cat-fact.herokuapp.com/facts"
Invoke-RestMethod -Uri $endpointUri | ConvertTo-Json -Depth 10 | Out-File -FilePath C:\Users\jlieske\Documents\catjson.json