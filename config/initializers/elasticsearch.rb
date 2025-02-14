# frozen_string_literal: true

client = if Rails.env.test?
           Elasticsearch::Client.new host: "https://#{Rails.application.secrets.elaticsearch_host}:9200", log: false
         else
           puts("AQUII ---------------------------")
           Elasticsearch::Client.new(
             host: ENV.fetch('ELASTICSEARCH_CONNECTION'),
             log: true
           )
         end

Elasticsearch::Model.client = client
Elasticsearch::Persistence.client = client
