def trigger_build(event, context):
    from google.cloud.devtools import cloudbuild_v1
    import sys
    import os
    import traceback
    client = cloudbuild_v1.CloudBuildClient()
    project_id = os.getenv('PROJECT_ID')
    trigger_id = 'terraform-builder-trigger'
    print(project_id)
    source = {"project_id": project_id, "branch_name": "master"}
    try:
        response = client.run_build_trigger(
          project_id = project_id,
          trigger_id = trigger_id,
          source = source)
        print("Called Trigger")
    except Exception as err:
        traceback.print_tb(err.__traceback__)
