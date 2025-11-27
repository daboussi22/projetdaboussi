
FROM eclipse-temurin:17-jre-alpine

ADD target/timesheet-devops-1.0.jar timesheet-devops-1.0.jar

EXPOSE 8092

ENTRYPOINT ["java", "-jar", "timesheet-devops-1.0.jar"]