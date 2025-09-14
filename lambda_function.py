import json
import boto3
import os

ec2 = boto3.client("ec2")

def handler(event, context):
    print("Received event:", json.dumps(event))

    instance_id = None

    # Case 1: CloudWatch Alarm State Change (direct invocation)
    if "detail-type" in event and event["detail-type"] == "CloudWatch Alarm State Change":
        detail = event["detail"]
        if "dimensions" in detail:
            dims = detail["dimensions"]
            for dim in dims:
                if dim.get("name") == "InstanceId":
                    instance_id = dim.get("value")
                    break

    # Case 2: GuardDuty Finding via EventBridge
    if "detail" in event and "resource" in event["detail"]:
        resource = event["detail"]["resource"]
        if "instanceDetails" in resource:
            instance_id = resource["instanceDetails"].get("instanceId")

    if instance_id:
        try:
            if "detail-type" in event and event["detail-type"] == "CloudWatch Alarm State Change" and detail.get("state") == "ALARM":
                isolation_sg = os.environ['ISOLATION_SG']
                isolation_rt = os.environ['ISOLATION_RT']
                invest_profile = os.environ['INVEST_PROFILE_ARN']

                # Get subnet_id
                response = ec2.describe_instances(InstanceIds=[instance_id])
                instance = response['Reservations'][0]['Instances'][0]
                subnet_id = instance['SubnetId']

                # Get current route table association_id
                rt_response = ec2.describe_route_tables(Filters=[{'Name': 'association.subnet-id', 'Values': [subnet_id]}])
                assoc_id = None
                for rt in rt_response['RouteTables']:
                    for assoc in rt['Associations']:
                        if 'SubnetId' in assoc and assoc['SubnetId'] == subnet_id:
                            assoc_id = assoc['AssociationId']
                            break
                    if assoc_id:
                        break

                if assoc_id:
                    ec2.replace_route_table_association(AssociationId=assoc_id, RouteTableId=isolation_rt)

                # Change security group
                ec2.modify_instance_attribute(InstanceId=instance_id, Groups=[isolation_sg])

                # Change IAM instance profile
                ec2.associate_iam_instance_profile(InstanceId=instance_id, IamInstanceProfile={'Arn': invest_profile})

            return {"action": "isolated" if "state" in detail and detail.get("state") == "ALARM" else "no_action", "instance": instance_id}
        except Exception as e:
            print("Error:", str(e))
            return {"error": str(e)}
    else:
        return {"message": "No instance ID found in event"}
