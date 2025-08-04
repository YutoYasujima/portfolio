set -o errexit

yarn install
bundle install
yarn run build:css
yarn run build
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate
bundle exec rails db:seed
