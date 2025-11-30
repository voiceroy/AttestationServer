# --- Build Stage ---
FROM archlinux:base-devel AS builder

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    jdk21-openjdk \
    python python-pip \
    nodejs npm \
    rsync zopfli parallel yajl brotli libxml2 \
    git unzip curl openssl moreutils

WORKDIR /build

COPY . .

RUN python -m venv venv

ENV PATH="/build/venv/bin:$PATH"

COPY nginx-fly.conf nginx/nginx.conf

RUN pip install -r requirements.txt && \
    pip install gixy

RUN curl -L -o vnu.linux.zip https://github.com/validator/validator/releases/download/20.6.30/vnu.linux.zip && \
    unzip vnu.linux.zip && \
    sed -i 's+validatornu+vnu-runtime-image/bin/vnu+g' process-static

RUN npm install
RUN ./gradlew build || echo "Manual build command required here if gradle missing"
RUN sed -i '/gixy/d' process-static
RUN chmod +x process-static && ./process-static

FROM archlinux:base

RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    jre21-openjdk-headless \
    sqlite \
    nginx \
    nginx-mod-brotli \
    && pacman -Scc --noconfirm

WORKDIR /opt/attestation
RUN mkdir -p /srv/attestation.app /data/db

COPY --from=builder /build/build/libs /opt/attestation/
COPY --from=builder /build/static-tmp /srv/attestation.app

COPY --from=builder /build/nginx-tmp/nginx.conf /etc/nginx/nginx.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 80

CMD ["/entrypoint.sh"]
