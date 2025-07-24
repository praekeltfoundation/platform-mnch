# Topics no response follow-up

This is a scheduled flow that gets set to run 15 minutes after the AAQ FAQ Topics List is displayed, but we received no input from the user

## Contact fields

* `nav_bypass` This is a mechanism to bypass the main menu and send the user straight to a sub section
* `aaq_metadata` This is used to keep track of the metadata from the latest AAQ call

## Flow results

* `aaq_faq_list_helpful`, Get set to `yes` or `no` depending on what the user clicks

## Connections to other stacks

* This is a scheduled reminder stack that gets set to run 15 minutes after the AAQ Topics List is shown, but we haven't received any input from the user

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` used to auth api calls to CMS
* `mc_ndoh_hub_token` used to authenticate calls to AAQ via MomConnect NDOH hub

## Content dependencies

* `mnch_onboarding_error_handling_button`
* `plat_help_topics_no_response_follow_up`
* `plat_help_acknowledgement_positive_`
* `plat_help_acknowledgement_negative_`

<!-- { section: "74f01d92-37ab-4c1e-8851-75f362fbde95", x: 0, y: 0} -->

```stack
card FetchError, then: TopicsNoResponseFollowup do
  # Get AAQ Metadata for sending feedback, and potentially redirecting the user back to the AAQ Results page
  aaq_metadata = parse_json("@contact.aaq_metadata")
  inbound_id = aaq_metadata.inbound_id
  feedback_secret_key = aaq_metadata.feedback_secret_key

  # Fetch and store the error message, so that we don't need to do it for every error card
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/mnch_onboarding_error_handling_button/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  button_error_text = page.body.messages[0].text
end

card GotoMainMenu do
  log("Going to Main Menu")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoFAQTopicsList do
  log("Going to GotoFAQTopicsList")
  update_contact(navbypass: "FAQTopicsList")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

card GotoHelpCentre do
  log("Going to GotoHelpCentre")
  update_contact(navbypass: "HelpCentre")
  run_stack("7b50f9f4-b6cf-424b-8893-8fef6d0f489b")
end

```

## Followup Message

```stack
card TopicsNoResponseFollowup, then: TopicsNoResponseFollowupError do
  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_topics_no_response_follow_up/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  callback_conf_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    TopicsNoResponseFollowupYes: "@button_labels[0]",
    TopicsNoResponseFollowupNo: "@button_labels[1]"
  ) do
    text("@callback_conf_msg")
  end
end

card TopicsNoResponseFollowupError, then: TopicsNoResponseFollowupError do
  buttons(
    TopicsNoResponseFollowupYes: "@button_labels[0]",
    TopicsNoResponseFollowupNo: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

## Information was helfpul

```stack
card TopicsNoResponseFollowupYes, then: TopicsNoResponseFollowupYesError do
  feedback_result =
    put(
      "https://hub.qa.momconnect.co.za/api/v1/inbound/feedback",
      body: """
      {
        "feedback_secret_key": "@feedback_secret_key",
        "inbound_id": "@inbound_id",
        "feedback": {
          "feedback_type": "positive",
          "page_number": "1"
        }
      }

      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  log("Page Feedback result = @feedback_result")
  write_result("aaq_faq_list_helpful", "yes")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_acknowledgement_positive_/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  conf_yes_msg = page.body.messages[0].text
  button_labels = map(page.body.messages[0].buttons, & &1.title)

  buttons(
    GotoFAQTopicsList: "@button_labels[0]",
    GotoMainMenu: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@conf_yes_msg")
  end
end

card TopicsNoResponseFollowupYesError, then: TopicsNoResponseFollowupYes do
  buttons(
    GotoMainMenu: "@button_labels[0]",
    GotoMainMenu: "@button_labels[1]",
    GotoMainMenu: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

## Information not helpful

```stack
card TopicsNoResponseFollowupNo, then: GotoFAQTopicsList do
  aaq_metadata = parse_json("@contact.aaq_metadata")
  inbound_id = aaq_metadata.inbound_id
  feedback_secret_key = aaq_metadata.feedback_secret_key
  user_question = aaq_metadata.user_question

  feedback_result =
    put(
      "https://hub.qa.momconnect.co.za/api/v1/inbound/feedback",
      body: """
      {
        "feedback_secret_key": "@feedback_secret_key",
        "inbound_id": "@inbound_id",
        "feedback": {
          "feedback_type": "negative",
          "page_number": "1"
        }
      }

      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  log("Page Feedback result = @feedback_result")
  write_result("aaq_faq_list_helpful", "no")

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v3/pages/plat_help_acknowledgement_negative_/",
      query: [
        ["channel", "whatsapp"]
      ],
      headers: [["Authorization", "Token @global.settings.contentrepo_qa_token"]]
    )

  callback_conf_no = page.body.messages[0].text
  text("@callback_conf_no")
end

```