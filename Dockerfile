FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    make \
    gcc \
    g++ \
    libnl-3-dev \
    libnl-route-3-dev \
    libprotobuf-dev \
    protobuf-compiler \
    pkg-config \
    bison \
    flex \
    && rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/google/nsjail.git /tmp/nsjail && \
    cd /tmp/nsjail && \
    make && \
    cp nsjail /usr/local/bin/ && \
    rm -rf /tmp/nsjail

WORKDIR /app

COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

RUN pip3 install --no-cache-dir \
    numpy \
    pandas \
    requests

COPY src/ ./src/
COPY nsjail.cfg .

RUN mkdir -p /tmp/sandbox

EXPOSE 8080

CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "4", "src.main:app"]
