#!/bin/bash

set -e

echo "=== Lambda Function Packaging Script ==="

cd terraform-infra/modules/lambda

# Install dependencies
echo "Installing dependencies..."
pip install boto3 -t . --upgrade

# Create deployment package
echo "Creating deployment package..."
zip -r lambda_function.zip lambda_function.py

echo "✓ Lambda package created: lambda_function.zip"
echo ""
echo "Now run: cd ../../environments/prod && terraform apply"
