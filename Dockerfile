#Account (Node)
FROM node:18-alpine AS build

WORKDIR /app

COPY . .

FROM node:18-alpine

COPY --from=build /app .

CMD ["node", "app.js"]

#Transaction (Java)
FROM openjdk:17-slim

WORKDIR /app

COPY . .

RUN javac Transaction.java

CMD ["java", "Transaction"]

#Notification (Py)
FROM python:3.9-slim

WORKDIR /app

COPY . .

RUN pip install flask

CMD ["python", "app.py"]
