bash:
	docker exec -it notifier_web_1 bash

start:
	docker-compose up

dev:
	rake start

dev_rc:
	rails c

prod:
	RAILS_ENV=production rake start

prod_rc:
	RAILS_ENV=production rails c
