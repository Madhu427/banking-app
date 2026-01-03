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
