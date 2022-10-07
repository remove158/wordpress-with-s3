up:
	terraform apply -auto-approve
down:
	terraform destroy -auto-approve
restart:
	make down
	make up