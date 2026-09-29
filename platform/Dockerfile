FROM tomcat:9.0-jre17-temurin
RUN rm -rf /usr/local/tomcat/webapps/*
COPY app/target/devops-e2e-app.war /usr/local/tomcat/webapps/devops-e2e-app.war
EXPOSE 8080
