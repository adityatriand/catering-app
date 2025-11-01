# Use Ruby 3.1.1 as specified in Gemfile
FROM ruby:3.1.1

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install -y nodejs npm sqlite3 libsqlite3-dev build-essential && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Install bundler
RUN gem install bundler

# Copy Gemfile and Gemfile.lock
COPY Gemfile Gemfile.lock ./

# Install dependencies
RUN bundle install

# Copy the rest of the application
COPY . .

# Make bin files executable
RUN chmod +x bin/*

# Create necessary directories
RUN mkdir -p tmp/pids log

# Precompile assets (optional, can be done at runtime)
# RUN bundle exec rails assets:precompile

# Expose port 3000
EXPOSE 3000

# Default command
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]

