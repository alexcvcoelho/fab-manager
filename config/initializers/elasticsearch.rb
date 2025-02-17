# frozen_string_literal: true

client = Elasticsearch::Client.new(
            host: Rails.application.secrets.elasticsearch_connection,
            log: true
          )

Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
