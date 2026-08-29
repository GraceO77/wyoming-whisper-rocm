FROM rocm/pytorch:rocm7.2.4_ubuntu24.04_py3.12_pytorch_release_2.10.0

ARG DEBIAN_FRONTEND=noninteractive
ARG WYOMING_VERSION=3.6.0
ARG CT2_VERSION=4.8.0
ARG CT2_WHEEL_URL=https://github.com/OpenNMT/CTranslate2/releases/download/v${CT2_VERSION}/rocm-python-wheels-Linux.zip

LABEL org.opencontainers.image.source="https://github.com/GraceO77/wyoming-whisper-rocm"
LABEL org.opencontainers.image.description="Wyoming Faster Whisper server with AMD ROCm acceleration for Home Assistant"
LABEL org.opencontainers.image.licenses="MIT"

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl unzip libsndfile1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Wyoming Faster Whisper and the optional Home Assistant prompt-biasing support.
RUN pip install --no-cache-dir "wyoming-faster-whisper[hass]==${WYOMING_VERSION}"

# The PyPI CTranslate2 wheel targets CUDA. Replace it with the official ROCm wheel.
# CTranslate2 retains the device name "cuda" for its ROCm backend.
RUN pip uninstall -y ctranslate2 && \
    curl -fsSL "${CT2_WHEEL_URL}" -o /tmp/ct2-rocm.zip && \
    unzip -j /tmp/ct2-rocm.zip \
      'temp-linux/ctranslate2-*-cp312-cp312-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl' \
      -d /tmp && \
    pip install --no-cache-dir /tmp/ctranslate2-*-cp312-*.whl && \
    rm -f /tmp/ct2-rocm.zip /tmp/ctranslate2-*.whl

VOLUME ["/data"]
EXPOSE 10300

ENTRYPOINT ["python", "-m", "wyoming_faster_whisper"]
CMD ["--uri", "tcp://0.0.0.0:10300", "--model", "turbo", "--language", "en", "--data-dir", "/data", "--download-dir", "/data", "--device", "cuda", "--compute-type", "float16"]
