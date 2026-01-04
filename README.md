                                                                               Banking APP

Setup Your Workspace on Azure
Create a VM: Go to the Azure Portal and create a Standard B1s (free tier eligible) Ubuntu 22.04 VM.

Open Ports: In the "Networking" tab, ensure ports 22 (SSH), 3000 (Account Service), and 5000 (Notification Service) are open.

Install Docker: SSH into your VM and run:

Bash

sudo apt update && sudo apt install docker.io -y

sudo usermod -aG docker $USER && newgrp docker

--------------------------------------------------------------------------------------------------------------------------                                                                               

Step 1: Create the Project Structure
Run these commands on your Azure VM to create the folders for all three services:
#######################################
Bash

mkdir banking-app && cd banking-app
mkdir account-service transaction-service notification-service
##########################################


Step 2: Create the Service Files
We will create "dummy" code for each to ensure they build and run.

1. Account Service (Node.js) nano account-service/app.js

JavaScript
----------------------------------------------------------
const express = require('express');
const app = express();
app.get('/', (req, res) => res.send('Account Service Active'));
app.listen(3000);
2. Transaction Service (Java/Spring Boot) For the assignment, you can use a simple JAR file or a basic Java container. nano transaction-service/Transaction.java

Java

public class Transaction {
    public static void main(String[] args) {
        System.out.println("Transaction Service Running...");
        while(true); // Keep container alive
    }
}

-----------------------------------------------------------------------------------
3. Notification Service (Python Flask) nano notification-service/app.py

Python
---------------------------------------
from flask import Flask
app = Flask(__name__)
@app.route('/')
def hello(): return "Notification Sent"
if __name__ == '__main__': app.run(host='0.0.0.0', port=5000)

---------------------------------------------------------------

Create Dockerfile for node.js

> banking-app/account-service/Dockerfile
-----------------------------------------
# Stage 1: Build
FROM node:18-alpine AS builder
WORKDIR /app
# Copy dependency files first to use Layer Caching
COPY package*.json ./
RUN npm install
# Copy the rest of your code
COPY . .

# Stage 2: Final Image
FROM node:18-alpine
WORKDIR /app
# Copy only the necessary files from the builder stage
COPY --from=builder /app .
EXPOSE 3000
CMD ["node", "app.js"]
------------------------------------------------

Create Docker file for python
> notification-service/Dockerfile
--------------------------------------------------
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install flask
CMD ["python", "app.py"]

-----------------------------------------------------

Create Docker file for java

> transaction-service/Dockerfile
--------------------------------------------

# Stage 1: Build stage (Uses JDK to compile)
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app
COPY . .
RUN javac Transaction.java

# Stage 2: Run stage (Uses JRE to run - much smaller)
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
# Only copy the compiled .class file from the build stage
COPY --from=build /app/Transaction.class .
CMD ["java", "Transaction"]

----------------------------------------
Create a docker-compose.yml file in the main banking-app folder. This handles the Docker Networking and Port Mapping requirements.


version: '3.8'
services:
  account:
    build: ./account-service
    ports:
      - "3000:3000"  # External Access
    networks:
      - banking-net

  notification:
    build: ./notification-service
    ports:
      - "5000:5000"  # External Access
    networks:
      - banking-net

  transaction:
    build: ./transaction-service
    # NO PORTS MAPPED - Internal only for security
    networks:
      - banking-net

networks:
  banking-net:
    driver: bridge

    command to run the docker compose is - docker-compose up



<img width="821" height="461" alt="image" src="https://github.com/user-attachments/assets/3302958f-defd-4628-ae26-cdf670348bed" />

    

<img width="601" height="230" alt="image" src="https://github.com/user-attachments/assets/585eb16b-29eb-414d-a488-004449a683da" />

    
<img width="508" height="261" alt="image" src="https://github.com/user-attachments/assets/d3cc6a9a-ec76-42c8-ad11-c0aa20389268" />


<img width="827" height="137" alt="image" src="https://github.com/user-attachments/assets/38dec9b3-fc85-4cac-977f-ce0337e3fedf" />


<img width="344" height="100" alt="image" src="https://github.com/user-attachments/assets/029322ff-54ba-4f8b-9c37-bd2667d09e6f" />


<img width="492" height="179" alt="image" src="https://github.com/user-attachments/assets/4de86092-510a-4d37-b008-ccbe22da4271" />

========================================================================================================================================

Part-2 Docker swarm Multi-Host Service Orchestration

<img width="574" height="226" alt="image" src="https://github.com/user-attachments/assets/3d1ccd5a-bd99-4ac1-908d-e4f06d996b57" />

For this Part i'm using GCP since i'm having issue with Azure and i'm creating 4 nodes due to some issue

Creating your VM Instances
In GCP, Virtual Machines are called Compute Engine Instances. To fulfill your assignment's requirement for a 5-node cluster, you need to create them manually or using a script.

Go to the Console: Search for "Compute Engine" in the GCP search bar.

Create Instance: Click "Create Instance."

Name: Call them manager-1, manager-2, manager-3, worker-1, and worker-2.

i'm creating only 2 Manager Nodes

Machine Type: For a student assignment, e2-micro or e2-small is enough and often falls under the "Free Tier."

Boot Disk: Ensure you select Ubuntu 22.04 LTS.

Advanced Networking: Click "Networking" and ensure they are all on the same default network so they can talk to each other internally.

Phase 2: Opening the "Firewall" (The most important step)
Just like on Azure, GCP blocks traffic by default. If you don't do this, you will get the "Timeout reached" error again.

Go to VPC Network: Search for "Firewall" in the GCP console.

Create Firewall Rule:

Name: allow-swarm-traffic

Targets: Select "All instances in the network."

Source Filter: Set to 0.0.0.0/0 (to allow you to access it) or 10.128.0.0/9 (to only allow internal VM talk).

Protocols and Ports:

TCP: 2377 (Manager communication), 7946 (Node discovery), 3000 (Account Service), 5000 (Notification Service).

UDP: 4789 (Overlay network traffic for Task 3), 7946.

Phase 3: Building the Swarm Step-by-Step
Now that your VMs are ready and the "gates" are open, you can link them.

SSH into Manager-1: Click the "SSH" button next to your VM in the GCP console.

Initialize the Cluster:

Bash

# GCP uses internal IPs for security. This command initializes the swarm.
docker swarm init --advertise-addr $(hostname -I | awk '{print $1}')
Join the other Managers:

On Manager-1, run: docker swarm join-token manager.

Copy that code, SSH into Manager-2 and Manager-3, and paste it.

Join the Workers:

On Manager-1, run: docker swarm join-token worker.

SSH into Worker-1 and Worker-2 and paste it.

<img width="637" height="133" alt="image" src="https://github.com/user-attachments/assets/5c46e18a-53ce-44bb-9723-041d430f464d" />

                      Deploying your SkillfyBank App

Edit your docker-compose.yml Find the networks section at the bottom of your file and change it to this

________
networks:
  banking-net:
    driver: overlay
    attachable: true
________

------------------------------
docker-compse.yml

version: '3.8'

services:
  account:
    image: madhu427/account-service:v1
    ports:
      - "3000:3000"
    networks:
      - banking-net
    deploy:
      replicas: 2
      restart_policy:
        condition: on-failure

  notification:
    image: madhu427/notification-service:v1
    ports:
      - "5000:5000"
    networks:
      - banking-net
    deploy:
      replicas: 2
      # Requirement: Auto-restart policy
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3
        window: 120s

  transaction:
    image: madhu427/transaction-service:v1
    # NO PORTS MAPPED - Internal only for security
    networks:
      - banking-net
    deploy:
      replicas: 2
      # Requirement: Rolling update strategy
      update_config:
        parallelism: 1
        delay: 10s
        order: start-first

networks:
  banking-net:
    driver: overlay
    attachable: true

    _---------------------------------------

Once you have saved the file, run the deploy command again on your Manager-1 node:

docker stack deploy -c docker-compose.yml skillfy-bank

run the below commands once deployment is done

docker network ls

docker stack services skillfy-bank 

<img width="670" height="215" alt="image" src="https://github.com/user-attachments/assets/e517be23-f7b1-4225-b070-28ec77c1e7e1" />


Evidence for Overlay Network: Run docker network ls. You should now see the network listed with the scope "swarm" and driver "overlay".

Evidence for Deployment: Run docker stack services skillfy-bank to see your 3 services running across the cluster.






