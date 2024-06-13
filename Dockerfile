FROM gradle:8.6-alpine as builder
WORKDIR /app
COPY --chown=gradle:gradle . /app
# Ask user to skip test in stage build? Or run within
RUN gradle clean build -x test --no-daemon

FROM amazoncorretto:17.0.11-al2023 as unwrapper
ENV APP_NAME="jmix-docker-0.0.1-SNAPSHOT.jar"
WORKDIR /app
COPY --from=builder /app/build/libs/${APP_NAME} /app/${APP_NAME}
RUN java -Djarmode=layertools -jar ${APP_NAME} extract

FROM amazoncorretto:17.0.11-al2023
WORKDIR /app
COPY --from=unwrapper app/dependencies/ ./
COPY --from=unwrapper app/spring-boot-loader/ ./
COPY --from=unwrapper app/snapshot-dependencies/ ./
COPY --from=unwrapper app/application/ ./
EXPOSE 8080
ENTRYPOINT ["java", "org.springframework.boot.loader.launch.JarLauncher"]