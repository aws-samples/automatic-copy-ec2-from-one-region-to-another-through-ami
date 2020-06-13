#!/bin/sh
read -p "Source region name, for example cn-north-1 :" srcregion   #variable
read -p "Destination region name, for example cn-northwest-1 :" dstregion    #variable
#file id is used to save all instance id that you want to migrate.
#file id-image-src file is used to save all EC2 instane ID and AMI ID so you can check which ECs has migrated.
#file imageid-src is used to save AMI id so you can use the describe-images API to check the status of the creating AMI task.
touch id-image-src
for instance_id in `cat ./id`
do
  echo $instance_id >> id-image-src
  aws ec2 create-image --instance-id $instance_id --name "TODST-"$instance_id --description "To Destination region AMI "$instance_id --no-reboot >> id-image-src
done
cat id-image-src | grep "ImageId" | sed 's/    "ImageId": //' | sed 's/"//g' > imageid-src
complete="yes"
while true
do
  for image_id in `cat ./imageid-src`
  do
    echo $image_id
    imagestatus=`aws ec2 describe-images --image-ids $image_id | grep "State" | grep "State" | sed 's/            "State": "//' | sed 's/",//'`
    echo $imagestatus
    if [ $imagestatus = "pending" ]
    then
       complete="no"
       echo "Please wait for a while, the Script is creating the AMI. Current time is: " `date`
       break
    fi
    complete="yes"
  done
  #echo $complete
  if [ $complete = "yes" ]
  then
    #echo $complete
    cat id-image-src | grep "i-*" | grep -v "ami" > id-src
    file1="id"
    file2="id-src"
    temp=`diff $file1 $file2 `
    if [ "$temp" == "" ]; then
    echo The AMI created successfully
    else
    echo Some AMIs creation fails, you may need to check the details in file "id-src"
    fi
    echo $temp
    break
  fi
  sleep 1
done
#After the create AMI operation completes, copy the AMI from source region to destination region
#file id-image-dst file is used to save AMI IDs so you can check which AMIs have copied.
#file imageid-dst is used to save AMI id so you can use the describe-images API to check the status of the copying AMI task.
#Please be notice that Destination Regions are limited to 50 concurrent AMI copies, if you have more than 50 ECs that need copy to destination region, please sperate 2 or more shell tasks. 
touch id-image-dst
for iamge_id_copy in `cat ./imageid-src`
do
  echo "ec2 copy-image --source-image-id "$iamge_id_copy" --source-region $srcregion --region $dstregion --name DST-"$iamge_id_copy
  aws ec2 copy-image --source-image-id $iamge_id_copy --source-region $srcregion --region $dstregion --name "DST-"$iamge_id_copy >> id-image-dst
done

cat id-image-dst | grep "ImageId" | sed 's/    "ImageId": //' | sed 's/"//g' > imageid-dst
completedst="yes"
while true
do
  for image_id_dst in `cat ./imageid-dst`
  do
    echo $image_id_dst
    imagestatusdst=`aws ec2 describe-images --image-ids $image_id_dst --region $dstregion | grep "State" | grep "State" | sed 's/            "State": "//' | sed 's/",//'`
    echo $imagestatusdst
    if [ $imagestatusdst = "pending" ]
    then
       completedst="no"
       echo "Please wait for a while, the Script is copying the AMI. Current time is: " `date`
       break
    fi
    completedst="yes"
  done
  if [ $completedst = "yes" ]
  then
    echo Checking the tasks
    break
  fi
  sleep 1
done
for image_id_dst_new in `cat ./imageid-dst`
  do
    aws ec2 describe-images --image-ids $image_id_dst_new --region $dstregion| grep Name |grep DST-| sed 's/            "Name": "//' | sed 's/DST-//' | sed 's/"//'>> srcimageid-dst
done
file3="srcimageid-dst"
file4=imageid-src
temp2=`diff $file3 $file4 `
if [ "$temp2" == "" ]; then
echo Automatic copy EC2s from Source region to Destination region through AMI completed successfully.
else
echo Some AMIs copy fails, you may need to check the details in file.
fi
echo $temp2
