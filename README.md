# Runpod Stable Video Diffusion

This is a container for Runpod (or actually any other system) with all the dependencies for stable video diffusion to run.

By default it automatically checks for a /workspace directory (default path for runpod's external volume mount, which can be changed with the `$MODEL_MOUNTPOINT` environment variable), downloads the weights for the model there, and runs the official streamlit demo on port 3000 by default (this can be changed with `$PORT` environment variable)

If you are using this image on your local machine you will need to mount a host directory to /workspace (or path specified in `$MODEL_MOUNTPOINT`) with at least 20 GB of free space (40 GB if downloading both models)

There are 3 different tags available: `svd-base-xt` downloads both models, and `svd-base`/`svd-xt` include only one model respectively

You can use it as a template for a pod: **[BASE](https://runpod.io/gsc?template=dove05wvcv)**, **[XT](https://runpod.io/gsc?template=0yuqqd2v24)**

## Example run commands (replace `/your/path` with your directory)
### With default model path/port
```
docker pull mnb3000/runpod-stable-video-diffusion:svd-xt
docker run --gpus all \
    -p 3000:3000 \
    -v /your/path:/workspace \
    -t mnb3000/runpod-stable-video-diffusion:svd-xt
```

### With custom model path & port
```
docker pull mnb3000/runpod-stable-video-diffusion:svd-xt
docker run --gpus all \
    -p 8080:8080 \
    -e MODEL_MOUNTPOINT=/model \
    -e PORT=8080 \
    -v /your/path:/model \
    -t mnb3000/runpod-stable-video-diffusion:svd-xt
```
