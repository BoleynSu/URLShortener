FROM maven@sha256:3c343205b17e59aa0756c936bf8c18f06e4145ad02dce28f3e258dcd18cfe8b3 as build
RUN microdnf install -y shadow-utils && useradd builder
WORKDIR /build
RUN chown builder:builder /build
USER builder
COPY --chown=builder ./ ./

RUN mvn package
RUN mkdir -p out
RUN mvn help:evaluate -q -Dexpression=project.version -DforceStdout > out/version
RUN mv target/urlshortener-$(cat out/version)-jar-with-dependencies.jar out/urlshortener.jar

FROM openjdk@sha256:d939191db6041b0a2a72b3545f21f603b3e5bbb173733f9193b35fd690ed347d
RUN microdnf install -y shadow-utils && microdnf clean all
COPY --from=build /build/out /urlshortener

RUN useradd -r urlshortener
USER urlshortener
VOLUME /data
EXPOSE 8080

ENV ADDRESS 0.0.0.0
ENV PORT 8080
ENV DB /data/db
# ENV USERNAME
# ENV PASSWORD

CMD java -Durlshortener-host=$ADDRESS \
         -Durlshortener-port=$PORT \
         -Durlshortener-db=$DB \
         -Durlshortener-username=$USERNAME \
         -Durlshortener-password=$PASSWORD \
         -jar /urlshortener/urlshortener.jar
