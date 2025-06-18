#!/bin/bash

# GitHub Branch Protection Setup Script
# Repository: GeneticxCln/HyprSupreme-Builder

REPO="GeneticxCln/HyprSupreme-Builder"
BRANCH="main"

echo "🔒 Setting up GitHub branch protection for $REPO..."
echo "Target branch: $BRANCH"
echo "==========================================="

# Check if gh CLI is authenticated
echo "Checking GitHub CLI authentication..."
if ! gh auth status > /dev/null 2>&1; then
    echo "❌ GitHub CLI not authenticated. Run 'gh auth login' first."
    exit 1
fi
echo "✅ GitHub CLI authenticated"

# Method 1: Try the new Rulesets API
echo "
📋 Method 1: Trying Rulesets API..."
ruleset_response=$(gh api repos/$REPO/rulesets \
  --method POST \
  --field name="Main Branch Protection" \
  --field enforcement="active" \
  --field target="branch" \
  --raw-field conditions='{"ref_name":{"include":["refs/heads/'$BRANCH'"]}}' \
  --raw-field rules='[
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 1,
        "dismiss_stale_reviews_on_push": true,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": true
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "required_status_checks": [],
        "strict_required_status_checks_policy": true
      }
    },
    {
      "type": "non_fast_forward"
    },
    {
      "type": "deletion"
    }
  ]' 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Ruleset created successfully!"
    echo "$ruleset_response" | jq . 2>/dev/null || echo "$ruleset_response"
    exit 0
else
    echo "❌ Rulesets API failed: $ruleset_response"
fi

# Method 2: Try legacy branch protection API
echo "
🔄 Method 2: Trying legacy branch protection API..."
protection_response=$(gh api repos/$REPO/branches/$BRANCH/protection \
  --method PUT \
  --raw-field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=true \
  --raw-field required_pull_request_reviews='{"required_approving_review_count":1,"dismiss_stale_reviews":true,"require_code_owner_reviews":false,"require_last_push_approval":false}' \
  --field restrictions=null 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Branch protection created successfully!"
    echo "$protection_response" | jq . 2>/dev/null || echo "$protection_response"
    exit 0
else
    echo "❌ Branch protection API failed: $protection_response"
fi

# Method 3: Check current protection status
echo "
🔍 Method 3: Checking current branch protection status..."
status_response=$(gh api repos/$REPO/branches/$BRANCH/protection 2>&1)
if [ $? -eq 0 ]; then
    echo "ℹ️  Current protection status:"
    echo "$status_response" | jq . 2>/dev/null || echo "$status_response"
else
    echo "ℹ️  No current protection found: $status_response"
fi

# All methods failed - provide manual instructions
echo "
❌ All automated methods failed. Manual setup required."
echo "==========================================="
echo "🌐 Please set up branch protection manually:"
echo "1. Go to: https://github.com/$REPO/settings/rules"
echo "2. Click 'New branch ruleset'"
echo "3. Configure:"
echo "   - Name: Main Branch Protection"
echo "   - Enforcement: Active"
echo "   - Target: Branch ($BRANCH)"
echo "   - Rules:"
echo "     ✅ Require pull request before merging (1 reviewer)"
echo "     ✅ Require status checks to pass"
echo "     ✅ Block force pushes"
echo "     ✅ Restrict deletions"
echo "     ✅ Restrict pushes"
echo "
🔧 Possible reasons for failure:"
echo "   - Insufficient permissions (need admin access)"
echo "   - Organization restrictions"
echo "   - API rate limits"
echo "   - Repository settings"

exit 1

