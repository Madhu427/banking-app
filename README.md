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


<img width="635" height="283" alt="image" src="https://github.com/user-attachments/assets/14c4754b-cb90-4c2b-aa3b-0ed9f2f11bb3" />

Validate Manager High Availability (HA)

The goal is to prove that if the "Leader" manager fails, the remaining managers elect a new leader and the cluster keeps running.

Check current roles: Run docker node ls on Manager-1. Identify which node is the Leader and which are Reachable.

Kill the Leader: Access the terminal of your Leader VM and stop the Docker service:

Bash

sudo systemctl stop docker

<img width="616" height="122" alt="image" src="https://github.com/user-attachments/assets/15036d2c-1ffd-4fb3-a7ce-3b774aacb974" />


To validate your Manager HA, Service Reallocation, and Auto-Restart Policy, you must perform a "controlled disaster" test. This proves that the SkillfyBank system can recover from both a hardware failure (VM down) and a software failure (app crash).

1. Validate Manager High Availability (HA)
The goal is to prove that if the "Leader" manager fails, the remaining managers elect a new leader and the cluster keeps running.

Check current roles: Run docker node ls on Manager-1. Identify which node is the Leader and which are Reachable.

Kill the Leader: Access the terminal of your Leader VM and stop the Docker service:

Bash

sudo systemctl stop docker
Verify Election: Go to a different manager (Manager-2) and run docker node ls again.

Evidence: The old leader should now be marked as Down/Unreachable. One of the other managers will automatically be promoted to Leader.

2. Validate Service Reallocation
This proves that when a node dies, Docker Swarm "moves" the banking services to a healthy VM.

Locate the Tasks: Run docker stack ps skillfy-bank to see which VMs are currently hosting your containers (e.g., Transaction-service running on Worker-1).

Simulate VM Failure: Go to your Google Cloud Console and "Stop" a VM that is currently running a task.

Check Recovery: Wait about 30 seconds and run docker stack ps skillfy-bank on a manager.

Evidence: You will see the tasks on the stopped VM marked as Shutdown. New tasks for those same services will automatically appear as Running on a different, healthy node.

<img width="677" height="343" alt="image" src="https://github.com/user-attachments/assets/797f1fab-52bc-4d53-a9e3-b03147bd26c3" />

Validate Auto-Restart Policy
This confirms that if a specific container crashes (but the VM is still fine), Docker restarts it based on your restart_policy.

Identify a Container: Run docker ps on any node to get the Container ID of one of your services (e.g., Notification-service).

Force a Crash: Kill the main process inside that specific container to simulate a software error:

Bash

docker kill <CONTAINER_ID>

<img width="659" height="208" alt="image" src="https://github.com/user-attachments/assets/5f29065d-e56e-40fb-9998-c00c5f9a808a" />


To add a custom health check to your multi-stage Dockerfile, you need to make two additions. First, you must install curl in the Run stage (Stage 2) because the JRE image is "slim" and doesn't include it by default. Second, you add the HEALTHCHECK instruction.

Since your Java file Transaction.java is likely a simple console application (not a web server), a standard HTTP health check using curl might fail. I will show you two ways to do this:

Option 1: The "Process Check" (Best for simple Java apps)
If your app does not start a web server on a port, use this to check if the Java process is still alive.

----------------------------------------------------------------------------
Dockerfile

# Stage 1: Build stage
FROM eclipse-temurin:17-jdk-jammy AS build
WORKDIR /app
COPY . .
RUN javac Transaction.java

# Stage 2: Run stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/Transaction.class .

# --- NEW: ADD HEALTHCHECK ---
# This checks if the Java process 'Transaction' is running in the process list
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD ps -ef | grep [j]ava || exit 1

CMD ["java", "Transaction"]
Option 2: The "Web Check" (Best for Spring Boot/Web apps)
If your application opens a port (e.g., 8080), use this. You must install curl first.

Dockerfile

# Stage 2: Run stage
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# 1. Install curl (Required for JRE images)
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

COPY --from=build /app/Transaction.class .

# 2. Add Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

CMD ["java", "Transaction"]

------------------------------------------------
How to verify it in your Swarm
After you build, push, and deploy this updated Dockerfile:

Wait 30 seconds (the interval you set).

Run the status command:

Bash

docker ps
Look for the status: Under the STATUS column, you should specifically see: Up 2 minutes (healthy)

If it says (unhealthy), it means your CMD command (the curl or the ps check) returned an error.

docker stack ps skillfy-bank

<img width="664" height="302" alt="image" src="https://github.com/user-attachments/assets/0d44b5a1-0894-45e8-97a2-b795e9332938" />











