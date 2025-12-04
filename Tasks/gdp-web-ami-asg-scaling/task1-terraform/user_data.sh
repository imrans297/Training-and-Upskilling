#!/bin/bash
yum update -y
yum install -y python3 python3-pip
pip3 install flask

mkdir -p /opt/gdp-web
cat > /opt/gdp-web/app.py << 'APPEOF'
#!/usr/bin/env python3
import os
import time
import socket
import urllib.request
from flask import Flask, jsonify

app = Flask(__name__)

def get_metadata():
    try:
        instance_id = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/instance-id', timeout=2).read().decode()
        public_ip = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/public-ipv4', timeout=2).read().decode()
        private_ip = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/local-ipv4', timeout=2).read().decode()
        ami_id = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/ami-id', timeout=2).read().decode()
        az = urllib.request.urlopen('http://169.254.169.254/latest/meta-data/placement/availability-zone', timeout=2).read().decode()
        return instance_id, public_ip, private_ip, ami_id, az
    except:
        return 'unknown', 'unknown', 'unknown', 'unknown', 'unknown'

@app.route('/')
def home():
    hostname = socket.gethostname()
    instance_id, public_ip, private_ip, ami_id, az = get_metadata()
    app_id = "${app_id}"
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())
    ami_backup_name = f"gdp-web-{app_id}-{time.strftime('%Y-%m-%d-%H-%M', time.gmtime())}"
    
    return f"""
    <html>
    <head>
        <title>GDP-Web-{app_id} - Terraform</title>
        <style>
            body {{ font-family: Arial; margin: 40px; background: #f5f5f5; }}
            .container {{ background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }}
            h1 {{ color: #{'#e74c3c' if app_id == '1' else '#3498db' if app_id == '2' else '#2ecc71'}; }}
            .info-table {{ width: 100%; border-collapse: collapse; margin: 20px 0; }}
            .info-table th, .info-table td {{ padding: 12px; text-align: left; border: 1px solid #ddd; }}
            .info-table th {{ background-color: #f8f9fa; font-weight: bold; }}
            .highlight {{ background-color: #fff3cd; font-weight: bold; }}
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 GDP-Web-{app_id} - Terraform Deployment</h1>
            
            <h2>📋 Instance Information</h2>
            <table class="info-table">
                <tr><th>Field</th><th>Value</th></tr>
                <tr class="highlight"><td><b>AMI Backup ID</b></td><td>{ami_id}</td></tr>
                <tr class="highlight"><td><b>AMI Backup Name</b></td><td>{ami_backup_name}</td></tr>
                <tr class="highlight"><td><b>Public IP</b></td><td>{public_ip}</td></tr>
                <tr class="highlight"><td><b>Version</b></td><td>1.0.0-Terraform</td></tr>
                <tr class="highlight"><td><b>Date</b></td><td>{timestamp}</td></tr>
                <tr class="highlight"><td><b>Hostname</b></td><td>{hostname}</td></tr>
                <tr><td>Instance ID</td><td>{instance_id}</td></tr>
                <tr><td>Private IP</td><td>{private_ip}</td></tr>
                <tr><td>Availability Zone</td><td>{az}</td></tr>
                <tr><td>Application</td><td>GDP-Web-{app_id}</td></tr>
                <tr><td>Deployment</td><td>Terraform</td></tr>
            </table>
            
            <h3>🔗 Quick Links</h3>
            <p>
                <a href="/json">JSON View</a> | 
                <a href="/health">Health Check</a>
            </p>
        </div>
    </body>
    </html>
    """

@app.route('/json')
def json_view():
    hostname = socket.gethostname()
    instance_id, public_ip, private_ip, ami_id, az = get_metadata()
    app_id = "${app_id}"
    timestamp = time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime())
    ami_backup_name = f"gdp-web-{app_id}-{time.strftime('%Y-%m-%d-%H-%M', time.gmtime())}"
    
    return jsonify({
        'ami_backup_id': ami_id,
        'ami_backup_name': ami_backup_name,
        'public_ip': public_ip,
        'version': '1.0.0-Terraform',
        'date': timestamp,
        'hostname': hostname,
        'instance_id': instance_id,
        'private_ip': private_ip,
        'availability_zone': az,
        'application': f'GDP-Web-{app_id}',
        'deployment': 'Terraform'
    })

@app.route('/health')
def health():
    return jsonify({'status': 'healthy', 'deployment': 'Terraform'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80, debug=False)
APPEOF

cat > /etc/systemd/system/gdp-web.service << 'SVCEOF'
[Unit]
Description=GDP-Web Application
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/gdp-web
Environment=APP_ID=${app_id}
ExecStart=/usr/bin/python3 /opt/gdp-web/app.py
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable gdp-web
systemctl start gdp-web