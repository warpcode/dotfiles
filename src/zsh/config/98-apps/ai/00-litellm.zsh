# LiteLLM API Configuration - only set when not at work
export LITELLM_BASE_URL="${LITELLM_API_ENDPOINT:-http://litellm.ai.warpcode.co.uk}"
export LITELLM_API_ENDPOINT="${LITELLM_API_ENDPOINT:-$LITELLM_BASE_URL/v1}"
export LITELLM_API_BASE="${LITELLM_API_BASE:-$LITELLM_API_ENDPOINT}"
export LITELLM_API_KEY="${LITELLM_API_KEY:-sk-1234}"  # Local only, insecure storage is acceptable
