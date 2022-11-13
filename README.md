
# GCP-Sample-Slackbot-Cloud-Function

An attempt to be the quickest way to get a standalone slackbot project up and running in GCP.

Inspired by:

  - https://slack.dev/bolt-python/tutorial/getting-started-http

and a lack of howtos for GCP.

## Why?
Slackbots are great! Serverless environments like Lambda and GCP Cloud functions are great! Combine the two in an easy to kickstart development framework and it's great!

## Concept of operations
The desired end state is a GCP project with a cloud source repo and cloud build triggers that terraform plan/apply on code commits. The build triggers will run terraform against a list of directories you choose (cicd by default) so you can use it to build the pipeline, infrastructure, groups, compute, databases, iam, etc as separate concerns as you see fit.

The `_managed_dirs` list in the `triggers.tf` file in the cicd directory sets the directories that will be managed by this cicd pipeline.

## Setup
You will need to be able to create a project with billing in the appropriate place in your particular org structure. First you'll run terraform locallly to initialize the project and the pipeline. After the project is created, we will transfer terraform state to the cloud bucket and from then on you can use git commits to trigger terraform changes without any local resources or permissions.

1. Clone this repo

2. Change directory (cd) to the **cicd directory** and edit the terraform.tfvars to match your GCP organization.

3. Run the following commands **in the cicd directory** to enable the necessary APIs,
   grant the Cloud Build service account the necessary permissions, and create
   Cloud Build triggers and the terraform state bucket:

    ```shell
    terraform init
    terraform apply
    ```
4. Get the name of the terraform state bucket from the terraform output

    ```shell
    terraform output
    ```
  and copy backend.tf.example as backend.tf with the proper bucket name.

    ```terraform
        terraform {
      backend "gcs" {
        bucket = "UPDATE_ME_WITH_OUTPUT_OF_INITIAL_INIT"
        prefix = "cicd"
      }
    }
    ```

  Note that if you create other directories for other terraform concerns, you should duplicate this backend.tf file in those directories with a different prefix so your state bucket matches your directory layout.

5. Now terraform can transfer state from your local environment into GCP. **From the cicd directory**:
    ```shell
    terraform init -force-copy
    ```

6. Follow the instructions at https://source.cloud.google.com/<project name>/<repository name> to then push your code (**from the parent directory of cicd, i.e. not the cicd directory**) into your new CICD pipeline. Basically:

    ```shell
    #from the root dir of your project, not cicd
    git init
    gcloud init && git config --global credential.https://source.developers.google.com.helper gcloud.sh
    git remote add google  https://source.developers.google.com/p/<project name>/r/<repository name>
    git checkout -b main
    git add cicd/configs/* cicd/backend.tf cicd/main.tf cicd/outputs.tf cicd/terraform.tfvars cicd/triggers.tf cicd/variables.tf
    git commit -m 'first push after bootstrap'
    git push --all google

7. After the repo and pipeline is established you should be able to view the build triggers and history by visiting:
https://console.cloud.google.com/cloud-build/dashboard?project=<project id here>

8. Next build the container that will be used by the CICD pipeline by changing to the container directory and issuing:

```
cd container
gcloud builds submit
```

9. Finally, use terraform to create the cloud function and upload the code that will be the basis of our slackbot:

You will want to create the bot parameters in your slack instance by following the guidance in: https://slack.dev/bolt-python/tutorial/getting-started-http#create-an-app

You will need a signing secret and a bot token to use when deploying this app using terraform.
Bot token is created via the oauth & permissions section and begins with an prefix of xoxb
Signing secret is available via the 'basic informaiton' page of the app. 
You will be asked for these values when you run terraform apply which will store them in google secret manager.

Be sure to rename the terraform.tfvars.example file as terraform.tfvars with an accurate project name, funciton name and then run:

```
cd code
terraform init
terraform apply
```

Next transfer this terraform state to your cloud repo by copying the backend.tf file into code dir and:

```
terraform init -force-copy
```

You will receive a URL of the function that you can use in your slack app configuration by appending /slack/events to the URL. Place this url in the 'event subscriptions' portion of the app config as follows (replace with https://your-url-goes-here/slack/events):
https://us-central1-prj-sample-slackbot-abcd.cloudfunctions.net/fnct-slackbot-prj-sample-slackbot-abcd/slack/events

Be sure to subscribe to these events:
- message.channels
- message.groups
- message.im
- message.mpim
- app_mention

## Secrets
According to https://github.com/hashicorp/terraform-provider-google/issues/9946 there is no way to use terraform to reference secrets stored in google secret manager and pass them to the function.

As delivered here, the variables you set for slack_bot_token and slack_signing_secret are stored as secrets in secret manager, but they are exposed as plain text environment variables to the function.

This means they are visible to anyone who can see the function configuration.

If you'd like to prevent this visibility, you can forgo using terraform to connect secrets to the function and do it manually via the console.

Navigate to your function:
- Choose Edit
- Under runtime, build, connections and security settings choose security
- Using the UI, expose slack_bot_token (latest) as environment variable SLACK_BOT_TOKEN and slack_signing_secret (latest) as environment variable SLACK_SIGNING_SECRET
- Choose next and redeploy the function

Finally, remove the environment variables section from the terraform script main.tf in the resource "google_cloudfunctions_function" "project_function" section.

Terraform apply will redeploy the function, but it will be able to access secrets using your manual configuration.

## CICD Container

The Docker container used for CICD executions is inspired by the
Cloud Foundation Toolkit (CFT) team. Documentations and scripts can be found
[here](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/master/infra/build/developer-tools-light).

This container is standalone and uses current versions of terraform and the gcloud sdk and includes necessary dependencies (e.g. bash, terraform, gcloud) to
validate and deploy Terraform configs.

## Continuous integration (CI) and continuous deployment (CD)

The CI and CD pipelines use
[Google Cloud Build](https://cloud.google.com/cloud-build) and
[Cloud Build triggers](https://cloud.google.com/cloud-build/docs/automating-builds/create-manage-triggers)
to detect changes in a cloud source repo, trigger builds, and implement terraform changes.

You can learn more about the build triggers, etc at:

- https://github.com/jeffbryner/gcp-project-pipeline

as this project uses the same triggers.

## Resources:

- https://www.sethvargo.com/managing-google-secret-manager-secrets-with-terraform/
- https://api.slack.com/start/building/bolt-python
- https://github.com/slackapi/bolt-python/blob/main/examples/google_cloud_functions/main.py
- https://github.com/slackapi/bolt-python
- https://api.slack.com/apis/connections/events-api
- https://api.slack.com/tutorials/tracks/responding-to-app-mentions
- https://slack.dev/bolt-python/tutorial/getting-started-http
