#!/usr/bin/env python3

## Script that queries AWS EC2 Spot Instance Price History for m5.large instances
## Update the region, time range, and InstanceTypes as needed.

import boto3
from datetime import datetime, timedelta
import argparse

def main():
    # Parse command-line arguments
    parser = argparse.ArgumentParser(description="A script to query AWS EC2 Spot Instance Price History.")
    parser.add_argument(
        '--region',
        type=str,
        default='us-east-2',
        help='AWS region to query (default: us-east-2)'
    )
    parser.add_argument(
        '--instance-type',
        type=str,
        default='m5.large',
        help='EC2 instance type to query (default: m5.large)'
    )
    args = parser.parse_args()

    # Create EC2 client
    client = boto3.client('ec2', region_name=args.region)

    # Query recent spot price history
    end_time = datetime.now()
    start_time = end_time - timedelta(days=1)  # Last 24 hours

    response = client.describe_spot_price_history(
        DryRun=False,
        StartTime=start_time,
        EndTime=end_time,
        InstanceTypes=[args.instance_type],
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