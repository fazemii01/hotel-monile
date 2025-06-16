# Use a base image with Java 17, which matches your project's requirement
FROM openjdk:17-jdk-slim

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper and pom.xml to cache dependencies
COPY ./mvnw .
COPY ./.mvn ./.mvn
COPY ./pom.xml .

# Download dependencies
RUN ./mvnw dependency:go-offline

# Copy the rest of your application source code
COPY ./src ./src

# Compile and package the application into a JAR file
RUN ./mvnw package -DskipTests

# Expose the port your application will run on (default for Spring Boot is 8080)
EXPOSE 8080

# The command to run your application
ENTRYPOINT ["java", "-jar", "target/hotel-0.0.1-SNAPSHOT.jar"]