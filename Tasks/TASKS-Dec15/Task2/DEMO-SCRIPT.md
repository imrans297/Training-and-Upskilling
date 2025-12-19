# Demo Script - Word-by-Word Guide

## Opening (30 seconds)

"Good morning/afternoon everyone. Today I'm going to demonstrate a serverless REST API that I built on AWS. This project showcases how to build a scalable, production-ready backend without managing any servers. Let me walk you through the architecture and then show you a live demonstration."

---

## Architecture Explanation (1 minute)

**[Show README.md architecture diagram]**

"The architecture is straightforward but powerful. When a client makes an HTTP request, it hits API Gateway, which acts as the front door. API Gateway routes the request to the appropriate Lambda function based on the HTTP method and path. The Lambda function processes the request, interacts with DynamoDB to store or retrieve data, and returns a response back through API Gateway to the client.

I've implemented three Lambda functions:
- AddProduct handles POST requests to create new products
- GetProduct retrieves a single product by ID
- ListProducts returns all products in the database

All of this runs serverless - no EC2 instances, no server management, and it automatically scales from zero to millions of requests."

---

## DynamoDB Demo (1 minute)

**[Show screenshot 01-dynamodb-table.png]**

"Let's start with the database layer. I'm using DynamoDB, AWS's NoSQL database service. Here you can see my Products table with a simple schema - productId as the partition key, along with name, price, and description fields.

I've chosen on-demand billing mode, which means I only pay for the read and write requests I actually use. The table automatically scales based on demand, and provides single-digit millisecond latency.

You can see I have a few sample products already in the table that we'll query in the live demo."

---

## Lambda Functions Demo (2 minutes)

**[Show screenshot 02-lambda-functions.png]**

"Now let's look at the business logic layer - the Lambda functions. All three functions are written in Python 3.12 and use the same IAM execution role.

**[Point to AddProduct function]**

The AddProduct function receives the request body from API Gateway, parses the JSON, and stores it in DynamoDB. One important detail here is converting the price to a Decimal type, which is required by DynamoDB's Python SDK.

**[Point to GetProduct function]**

GetProduct extracts the product ID from the URL path parameters, queries DynamoDB, and returns either the product data or a 404 if not found. I've implemented a custom DecimalEncoder to handle JSON serialization of DynamoDB's Decimal types.

**[Point to ListProducts function]**

ListProducts performs a scan operation to retrieve all products and returns them with a count. In production, you'd want to add pagination for large datasets, but for this demo, a simple scan works fine.

Each function is configured with 128MB of memory and a 10-second timeout. They all have CloudWatch logging enabled for monitoring and debugging."

---

## API Gateway Demo (1.5 minutes)

**[Show screenshot 03-api-gateway.png]**

"API Gateway is the entry point for all client requests. I've created a REST API called ProductsAPI with a clean resource structure.

The /products resource has two methods:
- POST for adding new products
- GET for listing all products

And /products/{id} has a GET method for retrieving a single product by its ID.

I've enabled Lambda Proxy Integration, which means API Gateway passes the entire request to Lambda and expects a properly formatted response. This gives us full control over status codes, headers, and response bodies.

CORS is enabled on all resources, so this API can be called from web browsers without cross-origin issues.

The API is deployed to the 'prod' stage, and you can see the invoke URL here. This is the public endpoint that clients use to access the API."

---

## Live Testing Demo (3 minutes)

**[Open Postman or terminal with curl]**

"Now for the exciting part - let's test the API live.

### Test 1: Add a Product

**[Execute POST request]**

I'm sending a POST request to /products with a JSON body containing productId, name, price, and description. 

**[Show response]**

And we get a 200 OK response confirming the product was added successfully. Behind the scenes, API Gateway invoked the AddProduct Lambda function, which stored this data in DynamoDB.

### Test 2: List All Products

**[Execute GET /products]**

Now let's retrieve all products with a GET request to /products.

**[Show response]**

Perfect! We get back an array of all products including the one we just added, along with a count. The ListProducts Lambda function scanned the DynamoDB table and returned all items.

### Test 3: Get Single Product

**[Execute GET /products/P001]**

Finally, let's get a specific product by ID. I'm requesting /products/P001.

**[Show response]**

Excellent! We get back just that one product. The GetProduct Lambda function performed a direct key lookup in DynamoDB, which is extremely fast.

**[Optional: Show error case]**

Let me also show error handling. If I request a product that doesn't exist...

**[Execute GET /products/INVALID]**

We get a proper 404 Not Found response with an error message. This shows the API handles edge cases gracefully."

---

## Security & IAM (1 minute)

**[Show screenshot 05-iam-role.png]**

"Security is critical in any cloud application. I've implemented the principle of least privilege using IAM roles.

The LambdaProductsAPIRole has exactly two policies:
- AWSLambdaBasicExecutionRole for writing logs to CloudWatch
- A custom policy granting only PutItem, GetItem, and Scan permissions on the Products table

No hardcoded credentials anywhere in the code. Lambda assumes this role at runtime and gets temporary credentials automatically.

Additionally, all data in DynamoDB is encrypted at rest by default, and API Gateway only accepts HTTPS connections, so data is encrypted in transit as well."

---

## Monitoring (45 seconds)

**[Show screenshot 06-cloudwatch-logs.png]**

"For monitoring and troubleshooting, all Lambda functions send logs to CloudWatch. You can see execution logs here with timestamps, duration, and memory usage for each invocation.

If there are any errors, they appear in these logs with full stack traces. I can also set up CloudWatch alarms to notify me if error rates exceed a threshold or if latency gets too high.

API Gateway also provides metrics on request count, latency, and error rates, giving full visibility into the API's health and performance."

---

## Cost Discussion (45 seconds)

"One of the best parts of serverless is the cost model. With the AWS free tier, this entire setup costs me nothing for the first year:
- 1 million Lambda requests per month free
- 1 million API Gateway requests per month free  
- 25GB of DynamoDB storage free

Even after the free tier, if this API handles 1000 requests per day, the monthly cost would be around $1 to $2. You only pay for what you use - no charges when the API is idle.

Compare that to running EC2 instances 24/7, which would cost at least $10-20 per month even with minimal traffic."

---

## Closing (1 minute)

"To summarize, I've built a production-ready serverless REST API that demonstrates:
- AWS Lambda for compute without servers
- API Gateway for HTTP routing and management
- DynamoDB for scalable NoSQL storage
- IAM for security and access control
- CloudWatch for monitoring and logging

The entire system automatically scales based on demand, requires zero server maintenance, and costs almost nothing at low traffic levels.

Some potential enhancements I could add include:
- UPDATE and DELETE operations to complete full CRUD
- Authentication using AWS Cognito or API keys
- Input validation to ensure data quality
- A CI/CD pipeline for automated deployments
- Infrastructure as Code using Terraform or CloudFormation

I have all the code, documentation, and Postman collections available if you'd like to review them in detail.

Are there any questions?"

---

## Common Q&A Responses

**Q: How long did this take to build?**
A: "About 2-3 hours including testing and documentation. The serverless approach significantly speeds up development since there's no infrastructure to configure."

**Q: What happens if Lambda fails?**
A: "Lambda automatically retries failed invocations. API Gateway will return a 502 error to the client. I can also configure Dead Letter Queues to capture failed events for later analysis."

**Q: Can this handle production traffic?**
A: "Absolutely. Lambda can handle thousands of concurrent executions, and API Gateway can handle 10,000 requests per second by default. Both can be increased with a support request. Companies like Netflix and Coca-Cola run production workloads on Lambda."

**Q: How do you test Lambda functions locally?**
A: "I can use AWS SAM CLI or LocalStack to run Lambda functions locally. I can also write unit tests using moto to mock AWS services."

**Q: What about vendor lock-in?**
A: "That's a valid concern. The business logic is in Python and could be containerized and run elsewhere. However, the tight integration with AWS services provides significant value that would be hard to replicate."

---

## Emergency Backup Script

**If live demo fails:**

"It looks like we're having a connectivity issue. Let me walk you through the screenshots of successful test runs I did earlier. [Show screenshot 04-test-results.png]

Here you can see all three endpoints working correctly - adding a product returns a success message, listing products returns the full array, and getting a specific product returns just that item. The response times are all under 100 milliseconds, showing the performance of the serverless architecture."

---

## Time Checkpoints

- 0:00 - Opening
- 0:30 - Architecture
- 1:30 - DynamoDB
- 2:30 - Lambda Functions
- 4:30 - API Gateway
- 6:00 - Live Testing
- 9:00 - Security
- 10:00 - Monitoring
- 11:00 - Cost
- 12:00 - Closing & Q&A

**Total: 12-15 minutes**

---

Good luck! Speak clearly, maintain eye contact, and show confidence in your work. 🚀
