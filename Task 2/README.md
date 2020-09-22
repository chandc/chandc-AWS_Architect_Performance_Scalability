### Introduction

Our task is to plan and provision a cost-effective AWS infrstructure for a new social media application development project for 50,000 single-region users.

Here are some of the design assumptions:

- 10% of the user population (or 5,000) will access the social media application concurrently
-  Each user will spend 30 seconds per page
- Each page can make up to 30 calls
- Each page will contain 30 MB of content (2/3 of them are static and will be served by S3 through CloudFront)

Based on the above assumptions, I came up with the following set of parameters as input to the AWS cost estimator.
| Design Parameter                              | Value          |
| :-------------------------------------------- | -------------- |
| unique DNS calls/month                        | 10 M           |
| Calls/month                                   | 720 B          |
| Data transfer among client, app and DB        | 720 TB/month   |
| Data transfer among client, CloudFront and S3 | 1,440 TB/month |
| Size of Static Content Store                  | 10 TB/month    |
|  | |

### Initial vs. Reduced Design

The initial budget is between \$8,000 and \$10,000 per month. The design guiding principle is to put as much data as possible in memory to reduce the number of performance bottlenecks.  Initial configuration costs \$9,308 a month and the challenge is to reduce this to less than \$6,500 per month. Looking at the budget, it is evident over 80% of the monthly cost is associated with the RDS instance, application servers and web servers, therefore my focus is to lower the cost of these three infrastructure components. The table below summarizes these adjustments. For the RDS instance, I have decided to use the ARM processor based instances. I lowered the CPU count and memory for the primary instance while keeping the read replica instance the same from CPU and memory perspectives. Since it is social media site, we will probably see more read than write requests, so the potential degradation in performance may not be noticeable by consumers.  These changes and the reduction in S3 storage yield the desired cost of \$6,405 per month.

| Service                              | Initial Config                                               | Reduced Config                                               |
| ------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Amazon  RDS for MySQL (Primary)      | On-Demand, db.r5.8xlarge, 32 vCPUs, 256GB memory, 1 TB  storage and 0.5TB Backup | On-Demand, db.m6g.4xlarge, 16 vCPUs, 64 GB mermory, 1 TB storage and 100 GB Backup |
| Amazon  RDS for MySQL (Read Replica) | On-Demand, db.r5.4xlarge, 16 vCPUs, 128 GB memory, 1 TB  storage | On-Demand, db.m6g.4xlarge, 16 vCPUs, 64 GB mermory, 1  TB storage |
| S3  Standard                         | 10 TB/month                                                  | 5 TB/month                                                   |
| Amazon  EC2 App                      | Savings Plans 1 Year, 5  instances m5.4xlarge, 16 vCPUs and 64 GB memory | Savings Plans 1 Year, 4  instances m5.4xlarge, 16 vCPUs and 64 GB memory |
| Amazon  Route 53                     | hosted in 1 zone                                             | no change                                                    |
| Elastic  Load Balancing              | 1 instance                                                   | no change                                                    |
| Amazon  EC2 - Web                    | Savings Plans 1 Year, 8  instances t3a.large, 2 vCPUs and 8 GB memory | no change                                                    |
| Amazon  Elastic IP                   | 1 for NAT Gateway                                            | no change                                                    |
| Amazon  Virtual Private Cloud (VPC)  | 1 NAT Gateway                                                | no change                                                    |
| Data  Transfer                       | inbound only                                                 | no change                                                    |


### Initial vs. Increased Design

With the budget ceiling increased to \$20,000 per month, I have decided to build resiliency to the primary RDS instance by activating multiple availability zones and increase the number of web and application instances so they can be placed in multiple zones. To improve performance, I added 2 more read replicas for a total of 3.  The monthly cost of this configuration is \$19,210.


| Service                               | Initial Config                                               | Increased Config                                             |
| ------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Amazon  RDS for MySQL (Primary)       | On-Demand, db.r5.8xlarge, 32 vCPUs, 256GB memory, 1 TB  storage and 0.5TB Backup | increase to multiple zones                                   |
| AAmazon  RDS for MySQL (Read Replica) | On-Demand, db.r5.4xlarge, 16 vCPUs, 128 GB memory, 1 TB  storage | 3 instances, On-Demand, db.r5.8xlarge, 32 vCPUs, 256 GB memory, 1 TB  storage |
| S3  Standard                          | 10 TB/month                                                  | 20 TB/month                                                  |
| Amazon  EC2 App                       | Savings Plans 1 Year, 5  instances m5.4xlarge, 16 vCPUs and 64 GB memory | increase to 10 instances                                     |
| Amazon  EC2 - Web                     | Savings Plans 1 Year, 8  instances t3a.large, 2 vCPUs and 8 GB memory | increase to 10 instances                                     |
| Amazon  Route 53                      | hosted in 1 zone                                             | no change                                                    |
| Amazon  Elastic IP                    | 1 for NAT Gateway                                            | no change                                                    |
| mazon  Virtual Private Cloud (VPC)    | 1 NAT Gateway                                                | no change                                                    |
| Data  Transfer                        | inbound only                                                 | no change                                                    |

