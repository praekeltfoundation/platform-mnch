```stack
trigger(interval: "+3m", relative_to: "contact.registration_started")
when contact.registration_status != "completed"

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
  name = if(is_nil_or_empty(contact.name), do: "", else: contact.name)
  message = substitute(message, "{{name}}", "@name")
  text("@message")
end

```