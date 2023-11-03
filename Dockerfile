FROM public.ecr.aws/lambda/python:3.9-arm64

ENV LEPTONICA_VERSION="1.83.1"
ENV TESSERACT_VERSION="5.3.3"
ENV TESSDATA_VERSION="tessdata"
# alternatively use: tessdata_fast, tessdata_best. More info here: https://github.com/tesseract-ocr
WORKDIR /tmp/

RUN yum install -y aclocal autoconf automake cmakegcc freetype-devel gcc gcc-c++ \
git lcms2-devel libjpeg-devel libjpeg-turbo-devel autogen autoconf libtool \
libpng-devel libtiff-devel libtool libwebp-devel libzip-devel make zlib-devel \
zip wget


COPY build_tesseract.sh /tmp/build_tesseract.sh
RUN chmod +x /tmp/build_tesseract.sh
CMD sh /tmp/build_tesseract.sh
