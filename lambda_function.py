import boto3 
import json
import logging


def lambda_handler(event, context):   
    array_of_rows_to_return = []
    status_code = 200

    try:
        event_body = event["body"]
        payload = json.loads(event_body)
        rows = payload["data"]
        for row in rows:
            row_number = row[0]
            metricName = row[1]
            value = row[2]
            unit = row[3]
            nameSpace = row[4]
            dimensionsArray = row[5]
    
            dimensionDict = json.loads(dimensionsArray)
            metricResponse = send_cloudwatch_metric(metricName, value, unit, nameSpace, dimensionDict)
            
            row_to_return = [row_number, metricResponse]
            array_of_rows_to_return.append(row_to_return)
        
        logging.info(f"array_of_rows_to_return: {array_of_rows_to_return}")
        json_compatible_string_to_return = json.dumps({"data" : array_of_rows_to_return})

    # Snowflake doesn't show error messsages from External Functions
    except Exception as e:
        print(e)
        logging.error(e)
        status_code = 400
        json_compatible_string_to_return = event_body

    return {
        "statusCode": status_code,
        "body": json_compatible_string_to_return
    }

def send_cloudwatch_metric(metricName, value, unit, nameSpace, dimensionDict):
    cloudwatch = boto3.client('cloudwatch')

    metricData = [
        {
            'MetricName': metricName, # Total_Elpased_Value
            'Dimensions': dimensionDict, 
            'Unit': unit, # Milisecounds
            'Value': value # snowflake value
        },
    ]
        
    response = cloudwatch.put_metric_data(
        MetricData = metricData,
        Namespace = nameSpace
    )

    return metricData