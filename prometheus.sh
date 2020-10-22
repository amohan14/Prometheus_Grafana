#!/usr/bin/env bash
install_nginx() {
    cd ~
    sudo apt-get update -y 
    sudo apt-get install nginx -y
}

install_prometheus() {
    sudo useradd --no-create-home --shell /bin/false prometheus
    sudo useradd --no-create-home --shell /bin/false node_exporter
    sudo mkdir /etc/prometheus
    sudo mkdir /var/lib/prometheus
    sudo chown prometheus:prometheus /etc/prometheus
    sudo chown prometheus:prometheus /var/lib/prometheus
    cd ~
    curl -LO https://github.com/prometheus/prometheus/releases/download/v2.22.0/prometheus-2.22.0.linux-amd64.tar.gz # latest version
    sha256sum prometheus-2.22.0.linux-amd64.tar.gz
    tar xvf prometheus-2.22.0.linux-amd64.tar.gz
    sudo cp prometheus-2.22.0.linux-amd64/prometheus /usr/local/bin/
    sudo cp prometheus-2.22.0.linux-amd64/promtool /usr/local/bin/
    sudo chown prometheus:prometheus /usr/local/bin/prometheus
    sudo chown prometheus:prometheus /usr/local/bin/promtool
    sudo cp -r prometheus-2.22.0.linux-amd64/consoles /etc/prometheus
    sudo cp -r prometheus-2.22.0.linux-amd64/console_libraries /etc/prometheus
    sudo chown -R prometheus:prometheus /etc/prometheus/consoles
    sudo chown -R prometheus:prometheus /etc/prometheus/console_libraries
    rm -rf prometheus-2.22.0.linux-amd64.tar.gz prometheus-2.22.0.linux-amd64
    sudo cat <<EOF >/etc/prometheus/prometheus.yml
    global:
       scrape_interval: 15s
    scrape_configs:
      - job_name: 'prometheus'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9090']
EOF
    sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
    # new systemd service file
    sudo cat <<EOF >/etc/systemd/system/prometheus.service
    [Unit]
    Description=Prometheus
    Wants=network-online.target
    After=network-online.target
    [Service]
    User=prometheus
    Group=prometheus
    Type=simple
    ExecStart=/usr/local/bin/prometheus \
        --config.file /etc/prometheus/prometheus.yml \
        --storage.tsdb.path /var/lib/prometheus/ \
        --web.console.templates=/etc/prometheus/consoles \
        --web.console.libraries=/etc/prometheus/console_libraries
    [Install]
    WantedBy=multi-user.target
EOF
    # using the newly created service
    sudo systemctl daemon-reload
    sudo systemctl start prometheus
    sudo systemctl enable prometheus
}

install_nodeexporter() {
    cd ~
    curl -LO https://github.com/prometheus/node_exporter/releases/download/v1.0.1/node_exporter-1.0.1.linux-amd64.tar.gz # latest
    sha256sum node_exporter-1.0.1.linux-amd64.tar.gz
    tar xvf node_exporter-1.0.1.linux-amd64.tar.gz
    sudo cp node_exporter-1.0.1.linux-amd64/node_exporter /usr/local/bin
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
    rm -rf node_exporter-1.0.1.linux-amd64.tar.gz node_exporter-1.0.1.linux-amd64
    # creating the Systemd service file for Node Exporter
    sudo cat <<EOF >/etc/systemd/system/node_exporter.service
    [Unit]
    Description=Node Exporter
    Wants=network-online.target
    After=network-online.target

    [Service]
    User=node_exporter
    Group=node_exporter
    Type=simple
    ExecStart=/usr/local/bin/node_exporter

    [Install]
    WantedBy=multi-user.target
EOF
    # reload systemd to use the newly created service
    sudo systemctl daemon-reload
    sudo systemctl start node_exporter
    sudo systemctl enable node_exporter
    sudo cat <<EOF >/etc/prometheus/prometheus.yml
    global:
      scrape_interval: 15s

    scrape_configs:
      - job_name: 'prometheus'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9090']
      - job_name: 'node_exporter'
        scrape_interval: 5s
        static_configs:
          - targets: ['localhost:9100']
EOF
    sudo systemctl restart prometheus
}

install_grafana() {
    sudo apt-get install -y adduser libfontconfig1
    wget https://dl.grafana.com/oss/release/grafana_7.2.2_amd64.deb
    sudo dpkg -i grafana_7.2.2_amd64.deb
    # Configure grafana server
    sudo /bin/systemctl daemon-reload
    sudo /bin/systemctl enable grafana-server.service
    sudo /bin/systemctl start grafana-server
      
}

# Runs the functions
echo "Setting up prometheus, nodeexporter and grafana on nginx server"
install_nginx
install_prometheus
install_nodeexporter
install_grafana
echo "Script Finished"