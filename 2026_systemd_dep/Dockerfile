FROM jrei/systemd-ubuntu:25.10

# 필요한 패키지 설치
RUN apt-get update && apt-get install -y nginx python3

# 서비스 파일 복사
COPY my-app.service /etc/systemd/system/
COPY my-nginx.service /etc/systemd/system/

# 서비스 활성화 (심볼릭 링크 생성)
RUN systemctl enable my-app.service my-nginx.service

# Nginx 기본 설정 제거 (충돌 방지용)
RUN rm /etc/nginx/sites-enabled/default

CMD ["/lib/systemd/systemd"]
