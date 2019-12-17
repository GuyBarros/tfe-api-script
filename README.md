# tfe-api-script
an implementation of Joern's TFE API script. shown in his great webinar [Demystifying the Terraform Enterprise API](https://www.hashicorp.com/resources/demystifying-the-terraform-enterprise-api)


there are two main scripts in this repo. one for TFE runs and another for Sentinel Policies

## Pre Reqs

there are few prerequisites we will need to run both scripts: 

 * TFE/TFC Token - either team or user works but needs to have enough priviledges to create all the content we need (workspaces, variables, policies e etc)

 * A Terraform project to run.  

 * A Sentinel Policy to upload

 ### Token
 The TFE/TFC Token needs to be saved in the the file named "tfe_team_token" 

 ### Terraform code
Any terraform project will do, just save into the "terraform_project" folder without any .terraform folder nor state files. 

also, feel free to add any dependency file, like certificates, licenses e etc.

what the script (and the API) does is , zips this folder and sends it to the TFE/TFC server as a Run. any variables this project needs must be added to the "variables.csv" file.

### Sentinel Policies
there are many ways to achieve this via the API, the way I've chosen to do this is create a policy set, create a policy, upload the sentinel policy, attach the policy to the policy set, attach the policy set to the workspace.

this is an example project as such, I only added one sentinel policy. 

the sentinel policy code must exist in the "sentinel_policies" 

## Terraform Run

there are 4 variables in the exec_code_api.sh that need to be update for this code to run correctly. the two most important ones are the organisation and workspace variable.

this code will create a Workspace, add the variables from the CSV file into that workspace, create a run configuration, attach the terraform project to that configuration, run the configuration and wait for a for the output of the run.

this code is set up to create all the steps; modify uses different APIs as such, if you want to recreate or rerun this script; please delete the created workspace before running again.(the script will fail otherwise).

once you've filled out all the variables and are ready to run the script: 
```bash
chmod +x exec_code_api.sh
./exec_code_api.sh
```

## Sentinel Policies

there are 6 variables in the exec_create_policies.sh that need to be update for this code to run correctly.besides that, we will also need to update the name of the sentinel policy used in line 116 :

```bash
  # create a policy
upload_result=$(
  curl -Ss \
  --header "Authorization: Bearer $tfc_token" \
  --header "Content-Type: application/octet-stream" \
  --request PUT \
  --data-binary @"./sentinel_policies/azure_instance_size.sentinel" \
  "https://app.terraform.io/api/v2/policies/${policy_id}/upload"
)
```

again, this code is set up to create all the steps; modify uses different APIs as such, if you want to recreate or rerun this script; please delete the created policy and policy set before running again.

once you've filled out all the variables and are ready to run the script: 
```bash
chmod +x exec_create_policies.sh
./exec_create_policies.sh
```



## TODO

 * correct the comments on exec_create_policies.sh
 * break the exec_code_api script into two, create and apply
 * 

any PR is welcomed. 


