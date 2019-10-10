FROM ruby:2.5

COPY action /action

ENTRYPOINT ["/action/entrypoint.sh"]
