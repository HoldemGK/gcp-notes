def trigger_build(event, context):
    from google.cloud.devtools import cloudbuild_v1
    import os
    client = cloudbuild_v1.CloudBuildClient()

    source = {"project_id": "test-tf-bulder", "branch_name": "master"}
    response = client.run_build_trigger(
      project_id = "test-tf-bulder",
      trigger_id = "terraform-builder-trigger",
      source = source)

if __name__=="__main__":
    trigger_build(event=None,context=None)
