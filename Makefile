.PHONY: help init plan apply destroy clean validate fmt

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

init: ## Initialize Terraform
	terraform init

plan: ## Show Terraform plan
	terraform plan

apply: ## Apply Terraform configuration
	terraform apply

destroy: ## Destroy all Terraform resources
	terraform destroy

validate: ## Validate Terraform configuration
	terraform validate

fmt: ## Format Terraform files
	terraform fmt -recursive

clean: ## Clean Terraform files
	rm -rf .terraform
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*

setup: ## Setup terraform.tfvars from example
	@if [ ! -f terraform.tfvars ]; then \
		cp terraform.tfvars.example terraform.tfvars; \
		echo "Created terraform.tfvars from example"; \
		echo "Please edit terraform.tfvars with your values"; \
	else \
		echo "terraform.tfvars already exists"; \
	fi

output: ## Show Terraform outputs
	terraform output
