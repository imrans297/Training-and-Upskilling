# Screenshots Guide

## Required Screenshots for Documentation

### 1. DynamoDB Table
**File:** `01-dynamodb-table.png`

**What to capture:**
- DynamoDB console showing Products table
- Table details (name, partition key, status)
- Items view with sample products

**Steps:**
1. Go to DynamoDB Console
2. Click on Products table
3. Take screenshot showing table overview
4. Click "Explore items" and capture items view

---

### 2. Lambda Functions
**File:** `02-lambda-functions.png`

**What to capture:**
- Lambda console showing all 3 functions
- Function configuration (runtime, role, timeout)
- Code editor with function code

**Steps:**
1. Go to Lambda Console
2. Capture list view showing AddProduct, GetProduct, ListProducts
3. Open one function and capture code view
4. Capture Configuration tab showing IAM role

---

### 3. API Gateway
**File:** `03-api-gateway.png`

**What to capture:**
- API Gateway resources tree
- Method configuration
- Deployment stage with Invoke URL

**Steps:**
1. Go to API Gateway Console
2. Open ProductsAPI
3. Capture Resources view showing /products and /products/{id}
4. Capture Stages → prod showing Invoke URL

---

### 4. Test Results
**File:** `04-test-results.png`

**What to capture:**
- Postman or curl test results
- Successful API responses
- All three endpoints tested

**Steps:**
1. Test POST /products - capture success response
2. Test GET /products - capture list response
3. Test GET /products/{id} - capture single item response
4. Create collage of all three results

---

### 5. IAM Role (Optional)
**File:** `05-iam-role.png`

**What to capture:**
- IAM role LambdaProductsAPIRole
- Attached policies
- Trust relationships

---

### 6. CloudWatch Logs (Optional)
**File:** `06-cloudwatch-logs.png`

**What to capture:**
- CloudWatch log groups for Lambda functions
- Sample log entries showing successful execution
- Metrics dashboard

---

## Screenshot Checklist

Before taking screenshots:
- [ ] Ensure all resources are created and active
- [ ] Test all API endpoints successfully
- [ ] Add sample data to DynamoDB
- [ ] Clear any sensitive information (account IDs, ARNs if needed)
- [ ] Use high resolution (1920x1080 or higher)
- [ ] Capture full browser window or relevant section

## Tools for Screenshots

### Windows
- Snipping Tool (Win + Shift + S)
- Snip & Sketch

### macOS
- Screenshot (Cmd + Shift + 4)
- Preview

### Linux
- Flameshot
- GNOME Screenshot (PrtScn)

### Browser Extensions
- Awesome Screenshot
- Nimbus Screenshot

## Naming Convention

```
[number]-[component]-[description].png

Examples:
01-dynamodb-table.png
02-lambda-functions-list.png
03-api-gateway-resources.png
04-test-results-postman.png
```

## Image Optimization

After capturing:
1. Crop unnecessary parts
2. Highlight important sections (red boxes/arrows)
3. Compress images (use TinyPNG or similar)
4. Keep file size under 500KB per image

## Adding to Documentation

Update README.md with:
```markdown
## Screenshots

### DynamoDB Table
![DynamoDB Table](screenshots/01-dynamodb-table.png)

### Lambda Functions
![Lambda Functions](screenshots/02-lambda-functions.png)

### API Gateway
![API Gateway](screenshots/03-api-gateway.png)

### Test Results
![Test Results](screenshots/04-test-results.png)
```
