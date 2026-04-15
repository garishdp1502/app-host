FROM ruby:2.5.1

# Sửa lỗi LegacyKeyValueFormat (Thêm dấu =)
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

# 1. Sửa lỗi GPG và Repo
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list && \
    sed -i 's|security.debian.org/debian-security|archive.debian.org/debian-security|g' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list

# 2. Cài đặt thư viện
RUN apt-get update -o Acquire::Check-Valid-Until=false \
    && apt-get install -y --no-install-recommends --allow-unauthenticated \
        imagemagick \
        libsqlite3-dev \
        nginx \
        dos2unix \
        nodejs \
    && rm -rf /var/lib/apt/lists/*

# 3. Cấu hình Bundler
RUN gem sources --add https://rubygems.org/ --remove https://gems.ruby-china.com/
RUN gem install bundler -v 1.17.3

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --without development test

COPY . .

# 6. Fix Line Endings
RUN find docker/ -name "*.sh" -exec dos2unix {} + && chmod +x docker/check_prereqs.sh

# 7. Biên dịch Assets
RUN rake assets:precompile

COPY docker/nginx.conf /etc/nginx/sites-enabled/app.conf

EXPOSE 8686

# Sửa lỗi JSONArgsRecommended (Dùng định dạng mảng cho CMD)
CMD ["/bin/bash", "-c", "docker/check_prereqs.sh ; bundle exec rake db:migrate ; service nginx start ; bundle exec puma -C config/puma.rb"]