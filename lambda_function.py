import json
import boto3

ec2 = boto3.client("ec2")

def handler(event, context):
    print("Received event:", json.dumps(event))

    instance_id = None

    # Case 1: CloudWatch Alarm via SNS
    if "Records" in event:
        # SNS payload
        message = json.loads(event["Records"][0]["Sns"]["Message"])
        if "Trigger" in message and "Dimensions" in message["Trigger"]:
            dims = message["Trigger"]["Dimensions"]
            for d in dims:
                if d["name"] == "InstanceId":
                    instance_id = d["value"]

    # Case 2: GuardDuty Finding via EventBridge
    if "detail" in event and "resource" in event["detail"]:
        resource = event["detail"]["resource"]
        if "instanceDetails" in resource:
            instance_id = resource["instanceDetails"].get("instanceId")

    if instance_id:
        try:
            ec2.stop_instances(InstanceIds=[instance_id])
            return {"action": "stopped", "instance": instance_id}
        except Exception as e:
            print("Error:", str(e))
            return {"error": str(e)}
    else:
        return {"message": "No instance ID found in event"}
