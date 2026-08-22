FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

RUN groupadd --system petclinic \
    && useradd --system --gid petclinic --no-create-home petclinic

COPY --chown=petclinic:petclinic target/spring-petclinic-*.jar app.jar

USER petclinic
EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
