#!/usr/bin/env python3

## Script that queries AWS EC2 Spot Instance Price History for m5.large instances
## Update the region, time range, and InstanceTypes as needed.

import boto3
from datetime import datetime, timedelta

client = boto3.client('ec2', region_name='us-east-2')

def main():
    # Query recent spot price history
    end_time = datetime.now()
    start_time = end_time - timedelta(days=1)  # Last 24 hours

    response = client.describe_spot_price_history(
        DryRun=False,
        StartTime=start_time,
        EndTime=end_time,
        InstanceTypes=['m5.large'],
        ProductDescriptions=['Linux/UNIX'],
        MaxResults=10,
    )

    print(f"Spot Price History Results: {len(response['SpotPriceHistory'])} entries\n")

    for item in response['SpotPriceHistory']:
        print(f"Timestamp: {item['Timestamp']}")
        print(f"Price: ${item['SpotPrice']}")
        print(f"Instance: {item['InstanceType']}")
        print(f"AZ: {item['AvailabilityZone']}")
        print(f"Product: {item['ProductDescription']}")
        print("-" * 60)

if __name__ == "__main__":
    main()