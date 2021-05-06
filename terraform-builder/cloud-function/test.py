def trigger_build(event, context):
    from google.cloud.devtools import cloudbuild_v1
    import os
    client = cloudbuild_v1.CloudBuildClient()

    project_id = os.getenv('PROJECT_ID')
    trigger_id = 'terraform-builder-trigger'
    source = {'project_id': project_id, 'branch_name': 'master'}
    response = client.run_build_trigger(project_id, trigger_id, source)

if __name__=="__main__":
    trigger_build(event=None,context=None)
