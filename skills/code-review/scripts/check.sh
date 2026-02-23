#!/bin/bash
# Code review helper script
# Performs automated checks for common issues

set -e

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "🔍 Running automated code review checks..."
echo ""

# Check for common security issues
echo "🔒 Security Checks"
echo "=================="

# Check for hardcoded secrets
echo -n "Checking for hardcoded secrets... "
if grep -rE "(password|passwd|pwd|secret|api_key|apikey|token|auth)\s*=\s*['\"][^'\"]+['\"]" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --exclude="*.md" --exclude="*.log" 2>/dev/null | grep -v "example\|sample\|dummy\|test" > /tmp/secrets.txt; then
    echo -e "${RED}⚠ Found potential secrets${NC}"
    cat /tmp/secrets.txt
else
    echo -e "${GREEN}✓ No obvious secrets found${NC}"
fi
echo ""

# Check for SQL injection vulnerabilities
echo -n "Checking for SQL injection risks... "
if grep -rE "(execute|query)\s*\(.*(\+|%|format)" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --include="*.py" --include="*.js" --include="*.java" 2>/dev/null > /tmp/sql.txt; then
    echo -e "${YELLOW}⚠ Potential SQL injection risk${NC}"
    cat /tmp/sql.txt | head -5
else
    echo -e "${GREEN}✓ No obvious SQL injection patterns${NC}"
fi
echo ""

# Check for command injection
echo -n "Checking for command injection risks... "
if grep -rE "(exec|system|eval|subprocess\.call)\s*\(" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --include="*.py" --include="*.js" --include="*.sh" 2>/dev/null > /tmp/exec.txt; then
    echo -e "${YELLOW}⚠ Found exec/eval usage - review carefully${NC}"
    cat /tmp/exec.txt | head -5
else
    echo -e "${GREEN}✓ No exec/eval patterns found${NC}"
fi
echo ""

# Code Quality Checks
echo "📊 Code Quality"
echo "==============="

# Find large files
echo "Largest files (potential refactoring candidates):"
find . -type f \( -name "*.py" -o -name "*.js" -o -name "*.java" -o -name "*.go" \) \
    -not -path "*/node_modules/*" -not -path "*/.git/*" -not -path "*/dist/*" -not -path "*/build/*" \
    -exec wc -l {} \; 2>/dev/null | sort -rn | head -5 | awk '{print "  " $2 " (" $1 " lines)"}'
echo ""

# Find TODO/FIXME comments
echo -n "TODO/FIXME items: "
TODO_COUNT=$(grep -r "TODO\|FIXME\|XXX\|HACK" . \
    --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=dist --exclude-dir=build \
    --exclude="*.md" 2>/dev/null | wc -l)
if [ "$TODO_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}$TODO_COUNT found${NC}"
else
    echo -e "${GREEN}None${NC}"
fi
echo ""

# Summary
echo "✅ Automated checks complete!"
echo ""
echo "Note: This is a basic automated check. Manual review is still essential for:"
echo "  - Logic errors and business rule violations"
echo "  - Architecture and design issues"
echo "  - Test coverage and quality"
echo "  - Performance implications"
echo "  - Context-specific requirements"
