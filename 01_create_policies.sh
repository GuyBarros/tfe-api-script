#!/bin/bash

# Make sure tfc_token environment variable is set
# to owners team token for organization

# Set address if using private Terraform Enterprise server.
# Set organization and workspace to create.
# You should edit these before running.

tfc_token=`cat tfe_team_token`
address="app.terraform.io"
organization="<MY_ORG>"
workspace="<MY_WORKSPACE>"
policyset="<MY_POLICY_SET>"
policy="<MY_POLICY>"
########################
# 01) Read WORKSPACE #
########################
# read workspace 
workspace_result=$(
  curl -Ss \
       --header "Authorization: Bearer $tfc_token" \
       --header "Content-Type: application/vnd.api+json" \
       "https://${address}/api/v2/organizations/${organization}/workspaces/${workspace}"
)
 

workspace_id=$(
  echo $workspace_result | jq -r ".data | .id "
)

echo "Workspace name" $workspace_id

########################
# 02) Check if policy set already exists
########################
policysets_result=$(
  curl -Ss \
  --header "Authorization: Bearer $tfc_token" \
  "https://${address}/api/v2/organizations/${organization}/policy-sets"
  )

   echo $policysets_result > return.json

########################
# 03) Create Policy Set JSON
########################

# # #Set the id workspace in policyset.json (create a payload.json)
# # sed -e "s/workspace_id/$workspace_id/" < policyset.template.json > policyset.json

#Set the id workspace in policyset.json (create a payload.json)
sed -e "s/placeholder/$policyset/" < policyset.template.json > policyset.json

# create a policyset
policyset_result=$(
  curl -Ss \
       --header "Authorization: Bearer $tfc_token" \
       --header "Content-Type: application/vnd.api+json" \
       --request POST \
       --data @policyset.json \
  "https://app.terraform.io/api/v2/organizations/${organization}/policy-sets"
)

echo $policyset_result > generated.json

policyset_id=$(
  echo $policyset_result | jq -r ".data |  .id "
)

echo "Policy Set created. PolicySetID: $policyset_id" && echo

 read -n 1 -r -p "Press any key to continue with STEP 04) Policies uploads configs"


########################
# 04) Create Policy Uploads
########################


#Set the name of the policy in policy.json (create a payload.json)
sed -e "s/placeholder/$policy/" < policy.template.json > policy.json

# create a policy
policy_result=$(
  curl -Ss \
       --header "Authorization: Bearer $tfc_token" \
       --header "Content-Type: application/vnd.api+json" \
       --request POST \
       --data @policy.json \
  "https://app.terraform.io/api/v2/organizations/${organization}/policies"
)

echo $policy_result > policy_result.json

policy_id=$(
  echo $policy_result | jq -r ".data |  .id "
)

echo "Policy created. PolicyID: $policy_id" && echo

 read -n 1 -r -p "Press any key to continue with STEP 05) uploads policy documents"


########################
# 05)  Upload Policy Document
########################


  # create a policy
upload_result=$(
  curl -Ss \
  --header "Authorization: Bearer $tfc_token" \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @"./sentinel_policies/azure_instance_size.sentinel" \
  "https://app.terraform.io/api/v2/policies/${policy_id}/upload"
)


echo $upload_result > upload_result.json


echo "Upload finished" && echo

 read -n 1 -r -p "Press any key to continue with STEP 06) Attach Policy to Policy Set"


########################
# 06)  Add Policies to the Policy Set 
########################


#Set the name of the policy in policy.json (create a payload.json)
sed -e "s/placeholder/$policy_id/" < attachpolicy.template.json > attachpolicy.json

 # create a policy
attach_result=$(
  curl -Ss \
    -H "Authorization: Bearer $tfc_token" \
  -H "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @attachpolicy.json \
  "https://app.terraform.io/api/v2/policy-sets/${policyset_id}/relationships/policies"
  )

  echo $attach_result > attach_result.json

  
########################
# 06)  Attach a Policy Set to workspaces 
########################



#Set the name of the policy in policy.json (create a payload.json)
sed -e "s/placeholder/$workspace_id/" < ps2ws.template.json > ps2ws.json

 # create a policy
ps2ws_result=$(
  curl -Ss \
    -H "Authorization: Bearer $tfc_token" \
  -H "Content-Type: application/vnd.api+json" \
  --request POST \
  --data @ps2ws.json \
  "https://app.terraform.io/api/v2/policy-sets/${policyset_id}/relationships/workspaces"
  )

  echo $ps2ws_result > ps2ws_result.json
