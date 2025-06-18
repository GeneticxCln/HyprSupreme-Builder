#!/bin/bash

# Simple GitHub Branch Protection Setup
REPO="GeneticxCln/HyprSupreme-Builder"
BRANCH="main"

echo "🔒 Setting up branch protection for $REPO ($BRANCH branch)..."

# Create temporary JSON files for the API calls
cat > /tmp/ruleset.json << 'EOF'
{
  "name": "Main Branch Protection",
  "enforcement": "active",
  "target": "branch",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/main"]
    }
  },
  "rules": [
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
  ]
}
EOF

# Try to create the ruleset
echo "📋 Attempting to create ruleset..."
result=$(gh api repos/$REPO/rulesets --method POST --input /tmp/ruleset.json 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ SUCCESS! Branch protection ruleset created!"
    echo "$result" | jq . 2>/dev/null
else
    echo "❌ Ruleset creation failed: $result"
    
    # Try legacy branch protection as fallback
    echo "🔄 Trying legacy branch protection..."
    
    cat > /tmp/protection.json << 'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": []
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "require_last_push_approval": false
  },
  "restrictions": null
}
EOF
    
    legacy_result=$(gh api repos/$REPO/branches/$BRANCH/protection --method PUT --input /tmp/protection.json 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ SUCCESS! Legacy branch protection created!"
        echo "$legacy_result" | jq . 2>/dev/null
    else
        echo "❌ Legacy protection also failed: $legacy_result"
        echo ""
        echo "🌐 Manual setup required:"
        echo "Go to: https://github.com/$REPO/settings/rules"
        exit 1
    fi
fi

# Clean up temp files
rm -f /tmp/ruleset.json /tmp/protection.json

echo "🎉 Branch protection setup complete!"

