import json
import boto3
import os

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

            return {"action": "isolated", "instance": instance_id}
        except Exception as e:
            print("Error:", str(e))
            return {"error": str(e)}
    else:
        return {"message": "No instance ID found in event"}