```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "engage")

```

## Re-Engagement SMS
```stack
card ReEngagementSms do
  content_data =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_reengagement_sms"],
        ["sms", "true"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = content_data.body.results[0].body.text.message
  text("@message")
end

```
