#!/bin/bash
# Gunicorn 서비스 재시작
sudo systemctl restart gunicorn

# Nginx 서비스 재시작
sudo systemctl restart nginx
