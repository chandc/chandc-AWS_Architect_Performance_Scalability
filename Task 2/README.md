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

The inital budget is between \$8,000 and \$10,000 per month. The design guiding principle is to put as much data as possible in memory to reduce the number of performance bottlenecks.  Initial configuration costs \$8,317 a month and the challenge is to reduce this to less than \$6,500 per month. Looking at the budget, it is evident 81% of the monthly cost is associated with the RDS instance, application servers and web servers, therefore my focus is to lower the cost by reducing the amount of memory and storage allocated to these three infrastructure components. The table summarizes these adjustments. For the RDS instance, I have decided to keep the same vCPU count using ARM processors and reduce the memory from 128 GB to 64 GB, database storage has been reduced from 1 to 0.5 TB, and backup size has been reduced from 500 GB and 100 GB. We could migitate potential performance hits by doing more proacitve DBA-type maintenance (e.g. indexing, data partitioning and archiving).  These changes alone reduce the cost by \$1,185 (or 65% of the saving we need to produce), additionl reduction in S3 storage and number of web and applications servers yields the desired cost of \$6,482 per month.

| Service                             | Initial Config                                               | Reduced Config                                               |
| ----------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Amazon  RDS for MySQL               | On-Demand, db.r5.4xlarge, 16 vCPUs, 128 GB memory, 1 TB  storage and 0.5TB Backup | On-Demand, db.m6g.4xlarge, 16 vCPUs, 64 GB mermory, 0.5  TB storage and 100 GB Backup |
| S3  Standard                        | 10 TB/month                                                  | 5 TB/month                                                   |
| Amazon  EC2 App                     | Savings Plans 1 Year, 5  instances m5.4xlarge, 16 vCPUs and 64 GB memory | Savings Plans 1 Year, 4  instances m5.4xlarge, 16 vCPUs and 64 GB memory |
| Amazon  Route 53                    | hosted in 2 Zones                                            | no change                                                    |
| Elastic  Load Balancing             | 2 instances                                                  | no change                                                    |
| Amazon  EC2 - Web                   | Savings Plans 1 Year, 8  instances t3a.large, 2 vCPUs and 8 GB memory | Savings Plans 1 Year, 6  instances t3a.medium, 2 vCPUs and 4 GB memory |
| Amazon  API Gateway                 | Average size for each request 10  KB                         | no change                                                    |
| Amazon  Elastic IP                  | 1 for NAT Gateway                                            | no change                                                    |
| Amazon  Virtual Private Cloud (VPC) | Inbound only                                                 | no change                                                    |
| Data  Transfer                      | inbound only                                                 | no change                                                    |


### Initial vs. Increased Design

With the budget ceiling increased to \$20,000 per month, I have decided to follow the origial guiding principle by increasing the memory in infrastructure components that can benefit from it, an obvious choice is the RDS instance which now has 246 GB of memory. I also improved the resilience by having a failover instance in the Ohio region. The RDS instance there will be initially set up as a read replica. As summarizes in the table below, the compute capacity in the Ohio failover region is slightly less than the primary site (for cost reason), therefore during the failure, users of the social media application might see a slight degradation in performance. The monthly cost of this configuration is \$19,606.


| Service                              | Initial Config                                        | Increased Config                                      |
| ------------------------------------ | ----------------------------------------------------- | ----------------------------------------------------- |
| Amazon  RDS for MySQL - VA           | On-Demand, db.r5.4xlarge, 1 TB  storage, 0.5TB Backup | On-Demand, db.r5.8xlarge, 1 TB  storage, 0.5TB Backup |
| Amazon  EC2 App - VA                 | Savings Plans 1 Year, 5  instances m5.4xlarge         | Savings Plans 1 Year, 5  instances m5.8xlarge         |
| Amazon  RDS for MySQL - OH (Replica) | None                                                  | On-demand db.r5.4xlarge, 1 TB  storage, 0.5 TB backup |
| S3  Standard                         | 10 TB/month                                           | no change                                             |
| Amazon  EC2 App - OH (Failover)      | None                                                  | Savings Plans 1 Year, 2  instances m5.8xlarge         |
| Amazon  EC2 Web - VA                 | Savings Plans 1 Year, 8  instances t3a.large          | Savings Plans 1 Year, 8  instances t3a.xlarge         |
| Amazon  EC2 Web - OH (Failover)      | None                                                  | Savings Plans 1 Year, 8  instances t3a.xlarge         |
| Amazon  Route 53                     | hosted in 2 Zones                                     | replicate in OH                                       |
| Elastic  Load Balancing              | 2 instances                                           | replicate in OH                                       |
| Amazon  API Gateway                  | Average size for each request 10  KB                  | replicate in OH                                       |
| Amazon  Elastic IP                   | 1 for NAT Gateway                                     |    replicate in OH                                          |
| Amazon  Virtual Private Cloud (VPC)  | Inbound only                                          |      replicate in OH                                        |
| Data  Transfer                       | Inbound only                                          |     replicate in OH                                         |

