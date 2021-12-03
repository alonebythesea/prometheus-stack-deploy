#!/bin/bash

################################################
#	Install docker and prometheus                #
################################################

sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

sudo yum install docker-ce docker-ce-cli containerd.io docker-compose -y
sudo systemctl start docker
sudo curl -L "https://github.com/docker/compose/releases/download/1.27.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

sudo cat<<EOF>docker-compose.yaml
version: '3.2'
services:
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus:/etc/prometheus/
    command:
      - --config.file=/etc/prometheus/prometheus.yml
    ports:
      - 9090:9090
    restart: always
  node-exporter:
    image: prom/node-exporter
    ports:
      - 9100:9100
    restart: always
    deploy:
      mode: global
  blackbox:
    image: bitnami/blackbox-exporter:latest
    ports:
      - 9115:9115
  grafana:
    image: grafana/grafana
    depends_on:
      - prometheus
    ports:
      - 3000:3000
    restart: always
  alertmanager:
    image: prom/alertmanager
    ports:
      - 9093:9093
EOF

################################################
#		Configuring prometheus                     #
################################################

self_ip=`ip addr list eth0 | grep "  inet " | head -n 1 | cut -d " " -f 6 | cut -d / -f 1`
sudo mkdir prometheus
sudo cat<<EOF>./prometheus/prometheus.yml
scrape_configs:
  - job_name: node
    scrape_interval: 5s
    static_configs:
    - targets: ['${self_ip}:9100','${remote_ip}:9100']
  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://onliner.by
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: ${self_ip}:9115
EOF

sudo /usr/local/bin/docker-compose up -d
