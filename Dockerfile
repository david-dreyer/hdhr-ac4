# This doesn't need to be the python image, but using it just so we are running the same OS as final
FROM python:3 AS ffmpeg
ARG TARGETARCH

WORKDIR /home

RUN LATEST=$(curl -s https://api.github.com/repos/MediaBrowser/Emby.Releases/releases/latest | grep "tag_name" | cut -d'"' -f4) && \
    curl -L -o emby.deb https://github.com/MediaBrowser/Emby.Releases/releases/download/${LATEST}/emby-server-deb_${LATEST}_${TARGETARCH}.deb && \
    ar x emby.deb data.tar.xz && \
    tar xf data.tar.xz

# Setup python and copy over ffmpeg
FROM python:3 AS final

WORKDIR /home

RUN apt-get install -y libfontconfig curl
COPY requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY *.py ./

COPY --from=ffmpeg /home/opt/emby-server/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=ffmpeg /home/opt/emby-server/lib/libav*.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/lib/libpostproc.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/lib/libsw* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libva*.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libdrm.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libmfx.so.* /usr/lib/
COPY --from=ffmpeg /home/opt/emby-server/extra/lib/libOpenCL.so.* /usr/lib/

EXPOSE 80
EXPOSE 5004

CMD ["/bin/bash", "-c", "uvicorn main:app --host 0.0.0.0 --port 80 --workers 2 & uvicorn main:tune --host 0.0.0.0 --port 5004 --workers 4"]
