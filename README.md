## Automatic copy EC2s from one region to another through AMI
Shell script that automates copy EC2s from one region to another through AMI.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## Prerequisites

aws cli - https://docs.aws.amazon.com/cli/latest/userguide/installing.html

The AWS CLI must be configured in the system where you are running the script from.

## Usage
The following diagram summarizes the script lifecycle.

1.	Save all ECs’ instance ID in file id, the file format should look like shown below:
i-0d92e9afb6da335cb
i-0df1ddea5b40691fa
i-01d23c7b37272053f
i-011c54507150ae6ff
2.	Keep the user profile in source region as default AWS CLI configuration
3.	Execute the shell
./copyami.sh
4.	Enter the Source region and Destination region

The script will create the first file id-image-src which is used to save all EC2 instance ID and AMI ID, so you can check which ECs have created the AMI.
The file imageid-src is used to save AMI ID so the script can use the describe-images API to check the status of the creating AMI task.
The file id-src is used to compare with id-image-src to see whether the AMI successfully created or not.
The file imageid-dst and id-image-src are used to save AMI id so the script can use describe-images API to check the status of the copying AMI task and which AMIs are copied to the destination region.
The file src-imageid-dst is used to compare with imageid-src to see whether the AMI successfully copied or not.

## Known Limitations
This script will not work if exceed 50 EC2s because the destination regions are limited to 50 concurrent AMI copies, please refer to https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/CopyingAMIs.html

Remove all files created if the task fails to complete.
