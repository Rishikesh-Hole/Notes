#!/bin/ksh

# Variables
CLIENT_ID="0007bd36-f5b4-4e24-8c8d-e8e931c259aa"
TENANT_ID="fb6ea403-7cf1-4905-810a-fe5547e98204"
RESOURCE="https://ubscloudapc.sharepoint.com"
CERT_FILE="/path/to/PoetsHfiSharePoint.ap.hedani.net.crt"
KEY_FILE="/path/to/PoetsHfiSharePoint.ap.hedani.net.key"
CHAIN_FILE="/path/to/PoetsHfiSharePoint.ap.hedani.net-chain.pem"
SITE_URL="https://ubscloudapc.sharepoint.com/teams/cssp16poetshfi1"
UPLOAD_FOLDER_PATH="/teams/cssp16poetshfi1/Shared Documents/yourfolder"
FILE_NAME="yourfile.txt"
FILE_CONTENT="This is the content of your file."

# Step 1: Create the JWT Assertion
JWT_HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT_CLAIMS=$(echo -n "{\"aud\":\"https://login.microsoftonline.com/$TENANT_ID/oauth2/token\",\"iss\":\"$CLIENT_ID\",\"sub\":\"$CLIENT_ID\",\"exp\":$(( $(date +%s) + 3600 )),\"nbf\":$(date +%s),\"jti\":\"id$(date +%s)\"}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT_SIGNATURE=$(echo -n "$JWT_HEADER.$JWT_CLAIMS" | openssl dgst -sha256 -sign $KEY_FILE | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT="$JWT_HEADER.$JWT_CLAIMS.$JWT_SIGNATURE"

# Step 2: Request an Access Token from Azure AD
ACCESS_TOKEN=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=$CLIENT_ID" \
  -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
  -d "client_assertion=$JWT" \
  -d "resource=$RESOURCE" | jq -r '.access_token')

# Step 3: Upload the File to SharePoint
curl -k -X POST "$SITE_URL/_api/web/GetFolderByServerRelativeUrl('$UPLOAD_FOLDER_PATH')/Files/add(url='$FILE_NAME',overwrite=true)" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Accept: application/json;odata=verbose" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @"$FILE_CONTENT" \
  --cert $CERT_FILE \
  --key $KEY_FILE \
  --cacert $CHAIN_FILE

# Step 4: Check for Success or Failure
if [ $? -eq 0 ]; then
  echo "File uploaded successfully!"
else
  echo "Error uploading file."
fi



#######################################
#!/bin/ksh

# Variables
CLIENT_ID="0007bd36-f5b4-4e24-8c8d-e8e931c259aa"
TENANT_ID="fb6ea403-7cf1-4905-810a-fe5547e98204"
RESOURCE="https://ubscloudapc.sharepoint.com"
P12_FILE="/sw/tis/core/PoetsHfiSharePoint.ap.hedani.net.p12"
P12_PASSWORD_FILE="/sw/tis/core/PoetsHfiSharePoint.ap.hedani.net.p12.pwd"
UPLOAD_FOLDER_PATH="/teams/cssp16poetshfi1/Documents/UserReports/ConnectionTesting"
FILE_NAME="Rishikesh.txt"
FILE_CONTENT="This is the content of your file."

# Read the password from the .pwd file
P12_PASSWORD=$(cat $P12_PASSWORD_FILE)

# Step 1: Create the JWT Assertion
JWT_HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT_CLAIMS=$(echo -n "{\"aud\":\"https://login.microsoftonline.com/$TENANT_ID/oauth2/token\",\"iss\":\"$CLIENT_ID\",\"sub\":\"$CLIENT_ID\",\"exp\":$(( $(date +%s) + 3600 )),\"nbf\":$(date +%s),\"jti\":\"id$(date +%s)\"}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT_SIGNATURE=$(echo -n "$JWT_HEADER.$JWT_CLAIMS" | openssl dgst -sha256 -sign $P12_FILE -passin pass:$P12_PASSWORD | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
JWT="$JWT_HEADER.$JWT_CLAIMS.$JWT_SIGNATURE"

# Step 2: Request an Access Token from Azure AD
ACCESS_TOKEN=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/token" \
    -d "grant_type=client_credentials" \
    -d "client_id=$CLIENT_ID" \
    -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    -d "client_assertion=$JWT" \
    -d "resource=$RESOURCE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//' | sed 's/"//')

# Step 3: Upload the File to SharePoint
response=$(curl -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Accept: application/json;odata=verbose" \
    -H "Content-Type: application/octet-stream" \
    --cert-type P12 --cert $P12_FILE:$P12_PASSWORD \
    --data-binary @"$FILE_CONTENT" \
    "$RESOURCE/_api/web/GetFolderByServerRelativeUrl('$UPLOAD_FOLDER_PATH')/Files/add(url='$FILE_NAME',overwrite=true)" \
    -o /dev/null -w "%{http_code}")

# Step 4: Check for Success or Failure
if [ "$response" -eq 200 ]; then
    echo "File uploaded successfully!"
else
    echo "Error uploading file. HTTP Status: $response"
fi
