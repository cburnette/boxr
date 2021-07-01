FROM ruby:2.7.3-alpine

LABEL maintainer="Volodymyr Kaban"

ARG APP_PATH=/home/appuser/boxr

ARG APP_USER=appuser
ARG APP_UID=1001

ARG APP_GROUP=appgroup
ARG APP_GID=1001

WORKDIR $APP_PATH

RUN addgroup $APP_GROUP -g $APP_GID -S && \
      adduser -S -s /sbin/nologin -u $APP_UID -G $APP_GROUP $APP_USER

RUN apk add git

USER $APP_USER

COPY --chown=$APP_USER:$APP_GROUP . $APP_PATH
