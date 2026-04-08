FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline          # cache deps layer separately
COPY src ./src
RUN mvn clean package -DskipTests
RUN JAR_FILE=$(ls -1 target/*.jar | grep -vE '(sources|javadoc|tests)\.jar$' | head -n1) \
    && test -n "$JAR_FILE" \
    && cp "$JAR_FILE" target/app.jar

FROM eclipse-temurin:17-jre
WORKDIR /app

RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
USER appuser

COPY --from=builder /app/target/app.jar app.jar

EXPOSE 8089
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
