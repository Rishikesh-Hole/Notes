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
P12_FILE="/path/to/PoetsHfiSharePoint.ap.hedani.net.p12"
P12_PASSWORD_FILE="/path/to/PoetsHfiSharePoint.ap.hedani.net.p12.pwd"
PUBLIC_CERT_FILE="/path/to/poetsPublicCert.pem"
TARGET_FILE="/path/to/uploadfile.txt"
SITE_URL="https://ubscloudapc.sharepoint.com/teams/cssp16poetshfi1"
UPLOAD_FOLDER_PATH="Shared Documents/yourfolder"
FILE_NAME=$(basename "$TARGET_FILE")
TENANT_ID="your-tenant-id"  # Replace with your Azure AD tenant ID
CLIENT_ID="your-client-id"  # Replace with your Azure AD application (client) ID
RESOURCE="https://ubscloudapc.sharepoint.com"  # Root URL for your SharePoint Online environment

# Read the password from the .pwd file
P12_PASSWORD=$(cat $P12_PASSWORD_FILE)

# Create the JWT header and payload
HEADER=$(echo -n '{"alg":"RS256","typ":"JWT"}' | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')
PAYLOAD=$(echo -n "{\"aud\":\"https://login.microsoftonline.com/$TENANT_ID/oauth2/token\",\"iss\":\"$CLIENT_ID\",\"sub\":\"$CLIENT_ID\",\"exp\":$(( $(date +%s) + 3600 )),\"nbf\":$(date +%s),\"jti\":\"$(uuidgen)\"}" | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Sign the JWT
SIGNATURE=$(echo -n "$HEADER.$PAYLOAD" | openssl dgst -sha256 -sign <(openssl pkcs12 -in $P12_FILE -nocerts -passin pass:$P12_PASSWORD) | base64 | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Construct the JWT assertion
JWT_ASSERTION="$HEADER.$PAYLOAD.$SIGNATURE"

# Get the access token using the JWT assertion
ACCESS_TOKEN=$(curl -s -X POST "https://login.microsoftonline.com/$TENANT_ID/oauth2/token" \
    -d "grant_type=client_credentials" \
    -d "client_id=$CLIENT_ID" \
    -d "client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer" \
    -d "client_assertion=$JWT_ASSERTION" \
    -d "resource=$RESOURCE" | grep -o '"access_token":"[^"]*"' | sed 's/"access_token":"//' | sed 's/"//')

# Check if the access token was successfully retrieved
if [ -z "$ACCESS_TOKEN" ]; then
    echo "Failed to retrieve access token"
    exit 1
fi

# Upload the file to SharePoint
response=$(curl -X POST \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Accept: application/json;odata=verbose" \
    -H "Content-Type: application/octet-stream" \
    --cert-type P12 --cert $P12_FILE:$P12_PASSWORD \
    --data-binary "@$TARGET_FILE" \
    "$SITE_URL/_api/web/GetFolderByServerRelativeUrl('$UPLOAD_FOLDER_PATH')/Files/add(url='$FILE_NAME',overwrite=true)" \
    -o /dev/null -w "%{http_code}")

# Check the response status
if [ "$response" -eq 200 ]; then
    echo "File uploaded successfully!"
else
    echo "Failed to upload file. HTTP Status: $response"
fi

