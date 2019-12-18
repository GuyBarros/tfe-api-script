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

####################################
# 02) Create configuration version #
####################################
configuration_version_result=$(
  curl -Ss \
       --header "Authorization: Bearer $tfc_token" \
       --header "Content-Type: application/vnd.api+json" \
       --request POST \
       --data @configversion.json \
       "https://${address}/api/v2/workspaces/${workspace_id}/configuration-versions"
  )

upload_url=$(
  echo $configuration_version_result | jq -r '.data.attributes."upload-url"'
)
configversion_id=$(
  echo $configuration_version_result | jq -r '.data.id'
)

echo "URL: $upload_url"
echo "configversion_id: $configversion_id" && echo

read -n 1 -r -p "Press any key to continue with STEP 03) Upload Configuration"

############################
# 03) Upload Configuration #
############################

#build myconfig.tar.gz
create_config=$(
  cd terraform_project
  tar -cvf myconfig.tar .
  gzip myconfig.tar
  mv myconfig.tar.gz ../.
  cd ..
)

echo "Config tar.gz created and ready for upload"
echo "imagine this code could also be cloned from a repository"

# Upload configuration
upload_config=$(
  curl -Ss \
       --header "Content-Type: application/octet-stream" \
       --request PUT \
       --data-binary @myconfig.tar.gz \
       "$upload_url"
)

echo "config uploaded..." && echo


read -n 1 -r -p "Press any key to continue with STEP 04) Run a plan"

##################
# 04) Run a Plan #
##################

sed -e "s/workspace_id/$workspace_id/" \
    -e "s/configversion_id/$configversion_id/" < run-plan.template.json > run-plan.json

run_plan=$(
  curl -Ss \
       --header "Authorization: Bearer $tfc_token" \
       --header "Content-Type: application/vnd.api+json" \
       --request POST \
       --data @run-plan.json \
       "https://${address}/api/v2/runs"
)

run_id=$(
  echo $run_plan | jq -r '.data.id'
)

echo "Run-ID: $run_id" && echo

read -n 1 -r -p "Press any key to continue with STEP 05 and 06) Check state and do apply"

#######################################################
# 05 & 06) Apply the plan if it is in the right state #
#######################################################

continue=1
while [ $continue -ne 0 ]
do
  # check status 
  check_status=$(
    curl -Ss \
         --header "Authorization: Bearer $tfc_token" \
         --header "Content-Type: application/vnd.api+json" \
         "https://${address}/api/v2/runs/${run_id}" |\
    jq -r '.data.attributes.status'
  )

  if [[ "$check_status" == "cost_estimated" ]] ; then
    continue=0
    # Do the apply
    echo "cost estimated. Doing apply..."
    apply_result=$(
      curl -Ss \
           --header "Authorization: Bearer $tfc_token" \
           --header "Content-Type: application/vnd.api+json" \
           --data @apply.json \
           "https://${address}/api/v2/runs/${run_id}/actions/apply"
    )
  elif [[ "$check_status" == "errored" ]]; then
    echo "Plan errored or hard-mandatory policy failed"
    continue=0
  else
    echo "current status: $check_status"
    sleep 5
  fi
done


