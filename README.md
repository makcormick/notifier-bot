# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

start in dev mode: rake start
start in prod mode: RAILS_ENV=production rake start
run docker with external db: docker run -v /tmp/db.sqlite3:/myapp/db/development.sqlite3 image_id

