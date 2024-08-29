# HelpCentre - Agent Greeting

This is a very basic flow, that sends a greeting message to the user, including the name of the help centre agent that is assigned to their query

## Contact fields

## Flow results

## Connections to other stacks

* This stack is manually run by the operator

## Global variables

* `turn_qa_token` used to authenticate calls to the Turn API.  In this case, to query and label a specific message
* `contentrepo_qa_token` used to auth calls to CMS API

## Content dependencies

* `plat_help_agent_greeting`

<!-- { section: "94da26e4-fe2e-42e6-b986-bdc0536cd585", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "tsts")

```

<!-- { section: "df9a9d5b-c57d-4a9e-8020-1756b7fdec73", x: 0, y: 0} -->

```stack
card GetLatestMessage, then: GetPageContent do
  get_latest_msg =
    get(
      "https://whatsapp-praekelt-cloud.turn.io/v1/contacts/@contact.whatsapp_id/messages",
      timeout: 5_000,
      cache_ttl: 60_000,
      headers: [
        [
          "Authorization",
          "Bearer @global.settings.turn_qa_token"
        ],
        ["Accept", "application/vnd.v1+json"],
        ["Content-Type", "application/json"]
      ]
    )

  chat = get_latest_msg.body.chat
end

card GetPageContent, then: SendGreeting do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_agent_greeting"]
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

  greeting_msg = page.body.body.text.value.message
end

card SendGreeting when is_nil_or_empty(chat.assigned_to) do
  substituted_msg = substitute(greeting_msg, "{operator_name}", "{a MomConnect operator}")

  text("@substituted_msg")
end

card SendGreeting do
  log("Agent assigned to this chat = @chat.assigned_to.name")
  substituted_msg = substitute(greeting_msg, "{operator_name}", "@chat.assigned_to.name")
  text("@substituted_msg")
end

```