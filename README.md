# Wyoming Faster Whisper ROCm for Unraid

A Home Assistant Wyoming speech-to-text server using **Wyoming Faster Whisper** with **AMD ROCm acceleration** via the official CTranslate2 ROCm wheel.

Designed for AMD ROCm-capable systems such as **Ryzen AI Max / Strix Halo (gfx1151)** running Unraid.

## What this provides

- Wyoming protocol server on TCP port `10300`
- `wyoming-faster-whisper` 3.6.0
- `faster-whisper` backend
- CTranslate2 4.8.0 ROCm wheel
- Default Whisper model: `turbo`
- Default language: English
- FP16 GPU inference
- Persistent model cache under `/data`
- Optional Home Assistant entity-name prompt biasing support is installed, but no HA credentials are baked into the image

> Note: CTranslate2 still uses the device name `cuda` for its ROCm backend. This is expected.

## Unraid requirements

The host must expose:

```text
/dev/kfd
/dev/dri
```

On the tested Unraid host, `/dev/kfd` and `/dev/dri` are assigned to group `video` with GID `18`, so the template includes:

```text
--group-add=18
```

If your host uses a different group ID, change the template Extra Parameters accordingly.

Check with:

```bash
getent group video
ls -l /dev/kfd
ls -l /dev/dri
```

## Install on Unraid

### Option 1: Use the included template

Download/copy:

```text
templates/Wyoming-Whisper-ROCm.xml
```

into:

```text
/boot/config/plugins/dockerMan/templates-user/my-Wyoming-Whisper-ROCm.xml
```

Then in Unraid:

**Docker → Add Container → Template → Wyoming-Whisper-ROCm**

The template uses:

```text
ghcr.io/graceo77/wyoming-whisper-rocm:latest
```

### Option 2: Docker CLI

```bash
docker run -d \
  --name Wyoming-Whisper-ROCm \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add=18 \
  -p 10300:10300 \
  -v /mnt/user/appdata/wyoming-faster-whisper-rocm/data:/data \
  --restart unless-stopped \
  ghcr.io/graceo77/wyoming-whisper-rocm:latest
```

## Verify ROCm GPU access

```bash
docker run --rm \
  --device=/dev/kfd \
  --device=/dev/dri \
  --group-add=18 \
  --entrypoint python \
  ghcr.io/graceo77/wyoming-whisper-rocm:latest \
  -c "import ctranslate2; print('GPU count:', ctranslate2.get_cuda_device_count())"
```

Expected output:

```text
GPU count: 1
```

## Home Assistant setup

In Home Assistant:

**Settings → Devices & services → Add Integration → Wyoming Protocol**

Use:

```text
Host: <Unraid server IP>
Port: 10300
```

Then select the discovered speech-to-text provider in your Assist pipeline.

## Default runtime arguments

The image starts Wyoming Faster Whisper with:

```text
--uri tcp://0.0.0.0:10300
--model turbo
--language en
--data-dir /data
--download-dir /data
--device cuda
--compute-type float16
```

## Home Assistant entity-name biasing

Wyoming Faster Whisper can optionally use Home Assistant entity, alias, area and floor names as prompt context to improve recognition of local names.

The required `hass` dependency is already installed in this image. To use it, add runtime arguments such as:

```text
--hass-token <LONG_LIVED_ACCESS_TOKEN>
--hass-api http://homeassistant.local:8123/api
```

Do not store access tokens in this public repository.

## Build locally

```bash
git clone https://github.com/GraceO77/wyoming-whisper-rocm.git
cd wyoming-whisper-rocm
docker build -t wyoming-whisper-rocm:latest .
```

## Updating

A GitHub Actions workflow publishes the image to GitHub Container Registry on pushes to `main` and on version tags.

Published image:

```text
ghcr.io/graceo77/wyoming-whisper-rocm:latest
```

## Upstream projects

- Wyoming Faster Whisper: https://github.com/OHF-Voice/wyoming-faster-whisper
- Faster Whisper: https://github.com/SYSTRAN/faster-whisper
- CTranslate2: https://github.com/OpenNMT/CTranslate2
