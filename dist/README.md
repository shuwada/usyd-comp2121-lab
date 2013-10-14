## Notes

- All students share one single AWS account in this exercise. Therefore, you can see other
students' virtual machines and login to them. You can even delete what other students have created.
Please be very careful and make sure to access/use resources you have created.

- The AWS account used in this exercise has minimum privilege. You are not allowed to execute many
operations such as terminating virtual machines, deleting queues and changing account settings.

- The AWS account used in this exercise can launch up to certain number of virtual machines in total.
Each student will launch two virtual machines in total in this exercise. Please do not launch more than two
instances.



## Setup

1. Setup aws-cli (http://aws.amazon.com/cli/)
1. Download http://xxx/config to your local machine
1. Create .aws directory in your home and copy the config file into it
1. Execute `aws iam get-user` on a terminal and check if it shows result something similar to below.

```
{
    "User": {
        "UserName": "students", 
        "Path": "/", 
        "CreateDate": "2013-09-24T03:31:43Z", 
        "UserId": "AIDAJR5GOUTSWN72ET4I4", 
        "Arn": "arn:aws:iam::517039496984:user/students"
    }
}
```


## Exercise 1

The first task is to launch a virtual machine instance in AWS and obtain its DNS name by making an API call from your machine.

1. Go to https://517039496984.signin.aws.amazon.com/console
1. login to AWS console. Username/password are students/comp2121
1. On top left, select "Services" - "EC2"
1. On top right, select "Sydney" region
1. Click "AMIs" from the left, find the image "comp2121" (or search `ami-2d4cd117`), select it, then press "Launch" button above
1. Select "M1 Small" instance type, press "Continue", "Continue" and "Continue"
1. Name your instance so that you can identify it later. Use unique name such as your name or student id.
1. Keep hitting "Continue". Then, hit "Launch" to launch an instance
1. Before closing the wizard, it shows the instance id (it looks like `i-f10ab9cd`.) Keep it somewhere.

Execute the following commands on your machine to make API calls and obtain the status of instances.

- Show all instances and their details in Sydney region in JSON format
```
aws ec2 describe-instances
```

- Show the status of one instance in one line. (Replace `i-f10ab9cd` with the id of your instance.)
```
aws ec2 describe-instances --output text | grep i-f10ab9cd
```

- Show the public DNS name of an instance. (Replace `i-f10ab9cd` with the id of your instance.)
```
aws ec2 describe-instances --output text | grep i-f10ab9cd | awk '{print $1}'
```

*Duration: 10 min*



## Exercise 2

The second task is to create a queue in AWS SQS and send a request to it.

1. Login to AWS console
1. On top left, select "Services" - "SQS"
1. On top right, make sure that Sydney region is selected
1. Press "Create New Queue" button
1. Give a unique name and press "Create Queue" button

Remember the URL of the queue you just created. You can find it in the details (bottom of the browser) and it looks like https://sqs.ap-southeast-2.amazonaws.com/517039496984/myqueue. (`myqueue` is the name of a queue.)

Next, download https://xxx/sqs_client.sh. Give execute permission by `chmod +x sqs_client.sh`. Then, execute it as follows.
Replace `myqueue` in the second parameter with the name of the queue you just created.

```
./sqs_client.sh ap-southeast-2 517039496984/myqueue 'hello world'
```

Go back to AWS console. Select your queue and execute "Queue Actions" - "View Messages" from the menu above.
Once pressing "Start Polling for Messages", you see your message in the queue.

Change the last parameter and execute `sqs_client.sh` couple times. Confirm your queue receives them.

Make sure to delete all requests in the queue before proceeding to the next exercise.

*Duration: 15 min*


## Exercise 3

The third task is to configure your virtual machine in AWS so that it starts a task triggers by a request in SQS.

1. ssh to the instance you launched in Excercise 1. Username/password are comp2121/password
1. Open `~/service.sh`. Search the following line and replace `your-queue-name-comes-here` with the name of your queue.
```
SQS_QUEUE_URL=https://sqs.$SQS_REGION.amazonaws.com/517039496984/your-queue-name-comes-here
```
1. After updateing `service.sh`, execute `vmstat 1` on your ssh terminal and leave it

The instance is configured to execute `/home/comp2121/service.sh` once every minute. The script watches your queue, executes
a CPU intensive task for 30 seconds if a message exists in the queue, and remove the request. The script creates a log file `~/service.log`.
It helps you troubleshoot.

Use `sqs_client.sh` used in Exercise 2 to send a request to your queue. Then, go to AWS console and watch
the number of messages in the queue. (Keep pressing "Refresh" button.) After a while, you will see that the
number of "Message Available" decreases by one and "Messages in Flight" increases by one. You also see the CPU
usage of your AWS instances goes up on the ssh terminal. Second from the last column of `vmstat` is the idle CPU time,
which hits 0%, and forth from the last column is the user time, which hits 100%. It means the instance has consumed
the request and started a task.

After 30 seconds, "Messages in Flight" decreases by one and the CPU usage of your instance goes down.
It indicates that the task has completed and the request has been removed from the queue.

*Duration: 15 min*


## Exercise 4

The last task is to create your own virtual machine image and launch a new virtual machine instance from the image
if your queue has too many waiting requests.

1. Go to AWS console and select your instance you've customized in Excercise 3
1. Select "Actions" - "Create Image (EBS AMI)", give a unique name, then press "Yes, Create"
1. Before closing the wizard, it shows the image id (it looks like `ami-6f4bd6dd`.) Keep it somewhere.
1. Wait until the status of your image becomes "available"
1. Download http://xxx/launcher.sh, give it execute permission, and execute it as follows.
   Replace `myqueue` and `ami-6f4bd6dd` with your queue name and image id, respectively.
```
./launcher.sh ap-southeast-2 517039496984/myqueue ami-6f4bd6dd
```

If your queue has 9 or less requests waiting, the script does nothing. Execute the script used in Excercise 2 (`sqs_client.sh`)
more than 10 times to send requests to your queues, then execute `launcher.sh` again. This time it launches a new instance from
the image you just created.

Once confirmed a new instance launched, go to AWS console and watch the number of requests in your queue over time.
It will reduce faster than before since you now have two instances processing requests from a queue in parallel.


*Duration: 15 min*


## Exercises 5 (for those who finished all above)

Extend the script used in Excercise 4 (`launcher.sh`) to address the following requirements.
The script is designed to be able to launch up to one instance. Remove the limitation first.

### Scaling Out/In

- Reduce the size of the instance pool to one automatically when number of waiting requests is small
- Increase the number of instances so that a request in a queue does not wait too long (e.g., 10 minutes) to be processed
- The aggregate CPU usage of instances in the pool must be maintained at a high level (e.g., above 50%), within reasonable monitoring resolution, unless there are no jobs

### Fault Tolerance

- There should be at least 1 instance active at all times
- Each request needs to be processed at least once. Make sure to cleanly handle an instance failure or termination (on scaling-in)
- The service needs to be able to resume or restart autonomously on failure of major components

### Additional requirements

- To reduce the instance usage cost under fluctuating workload, take into account billing cycles before terminating instances
- On scaling in, make sure not to terminate an instance that is processing a request. This helps avoid extra turnaround time for the request due to retry.