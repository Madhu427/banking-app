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







