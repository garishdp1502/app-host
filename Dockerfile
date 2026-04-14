FROM ruby:2.5.1

ENV RAILS_ENV production

# 1. Sửa link repo về Archive
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# 2. Tắt kiểm tra thời gian khóa GPG và cài đặt package
RUN apt-get update -o Acquire::Check-Valid-Until=false \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        imagemagick \
        libsqlite3-dev \
        nginx \
    && rm -rf /var/lib/apt/lists/*

# Các bước sau giữ nguyên...

# Dùng nguồn gem mặc định cho nhanh
RUN gem sources --add https://rubygems.org/ --remove https://gems.ruby-china.com/
RUN gem install bundler -v 1.17.3

WORKDIR /app
ADD Gemfile* ./
RUN bundle install
COPY . .
COPY docker/nginx.conf /etc/nginx/sites-enabled/app.conf

# Đảm bảo script có quyền thực thi (Quan trọng trên Mac/Linux)
RUN chmod +x docker/check_prereqs.sh

RUN rake assets:precompile
EXPOSE 8686
CMD /bin/bash docker/check_prereqs.sh && service nginx start && puma -C config/puma.rb