Terraform Task:
===============
1) Create VPC
2) Create Internet gateway
3) Create Custom Route Table
4) Create Subnet
5) Associate subnet with Route Table
6) Create Security Group to allow port 22.80,443
7) Create a network interface with an ip in the subnet that was created in step 4
8) Assign an elastic IP to the network interface created in step 7
9) Create Ubuntu server and install/enable apache2

Note: 
1) Create single main.tf which will be created the above resources and do not hardcode the id's.
2) Configure s3 as backend and dynamo db locking for multi user execution.
