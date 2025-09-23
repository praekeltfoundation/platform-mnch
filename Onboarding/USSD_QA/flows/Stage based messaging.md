<!-- { section: "a1056a51-f937-4f51-804e-b10c63411f1a", x: 0, y: 0} -->

```stack
card GetTopics, then: DisplayTopics do
  slug = "sbm-topics-week-25"

  update_contact(name: "Bobbo")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "@slug"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["ussd", "true"],
        ["message", 1]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  topics_message = page.body.body.text.message
  # We subtract 1 because you can't select the first message, you start there by default
  # Then there are 4 options on the first message that you can navigate to (including the end message)
  num_messages = page.body.body.total_messages - 1
end

# 
card DisplayTopics, then: DisplayTopicsError do
  question_response = ask("@topics_message")

  assertion =
    isnumber(question_response) and question_response > 0 and question_response <= num_messages
end

card DisplayTopicsError when assertion == false do
  # invalid input, ask again
  then(DisplayTopics)
end

card DisplayTopicsError do
  then(GetSpecificTopic)
end

card GetSpecificTopic, then: DisplaySpecificTopic do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "@slug"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  page_id = search.body.results[0].id

  # Add 1 because the first message was 1, options start at 2
  message_id = question_response + 1

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      query: [
        ["ussd", "true"],
        ["message", "@message_id"]
      ],
      headers: [["Authorization", "Token @global.config.contentrepo_token"]]
    )

  message = page.body.body.text.message
end

card DisplaySpecificTopic when question_response < num_messages, then: DisplaySpecificTopicError do
  question_response = ask("@message")
end

card DisplaySpecificTopic do
  # End
  text("@message")
end

card DisplaySpecificTopicError when isnumber(question_response) and question_response == 1 do
  then(DisplayTopics)
end

card DisplaySpecificTopicError do
  # invalid input, ask again
  then(DisplaySpecificTopic)
end

```