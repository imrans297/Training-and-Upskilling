#!/bin/bash
# output Fomatting

# Basic Echo
echo "Simple Message"
echo -n "No newline"
echo " - continued"

# Printf formatting
printf "Name: %-10s Age: %3d\n" "John" 25
printf "Price: $%.2f\n" 19.99

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${RED}Error message${NC}"
echo -e "${GREEN}Success message${NC}"
echo -e "${YELLOW}Warning message${NC}"

cat << EOF
This is a multi-line
output using here document.
Current user: $(whoami)
Current date: $(date)
EOF