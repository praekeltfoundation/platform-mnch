# Scheduled - Query rating

This flow follows up with the user, whether their query was successfully resolved or not.

It only runs if the helpdesk agent does not run the 'Agent Wrap up' flow manually after the call

```stack
card FetchError, then: ScheduledQueryRating do
  # Fetch and store the error message, so that we don't need to do it for every error card
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "mnch_onboarding_error_handling_button"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  # We get the page ID and construct the URL, instead of using the `detail_url` directly, because we need the URL parameter for `get` to start with `https://`, otherwise stacks gives us an error
  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  button_error_text = page.body.body.text.value.message
end

card GotoAgentHelpfulResponse do
  log("Going to GotoAgentHelpfulResponse")
  update_contact(navbypass: "AgentHelpfulResponse")
  run_stack("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
end

```

<!-- { section: "4a1105b6-0e2f-41c4-bae1-75fd3a3ed9fa", x: 0, y: 0} -->

```stack
card ScheduledQueryRating, then: ScheduledQueryRatingError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_scheduled_query_rating"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["whatsapp", "true"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  query_rating_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    GotoAgentHelpfulResponse: "@button_labels[0]",
    No: "@button_labels[1]"
  ) do
    text("@query_rating_msg")
  end
end

card No do
  log("Going to GotoUnresolvedWhatNext")
  update_contact(navbypass: "UnresolvedWhatNext")
  run_stack("2d3f1f0e-6973-41e4-8a18-e565beeb3988")
end

card ScheduledQueryRatingError, then: ScheduledQueryRatingError do
  buttons(
    GotoAgentHelpfulResponse: "@button_labels[0]",
    No: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```