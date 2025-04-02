Add markdown here

# Intro to HelpCentre

This is the main flow that users interact with at the HelpCentre.

They are directed here to complete their profile for pregnancy health if they are pregnant, have a partner who is pregnant, or are curious about the content.

All content for this flow is stored in the ContentRepo. This stack uses the ContentRepo API to fetch the content, referencing it by the slug. A list of these slugs can be found at the end of this stack.

## Contact fields

* `returning_help_centre_user`, This field gets set to `true` once the user visits the HelpCentre.
* `nav_bypass`, This is a mechanism to bypass the main menu and send the user straight to a sub section
* `aaq_metadata` This is used to keep track of the metadata from the latest AAQ call
* `route_to_operator_origin` used to save of the route the user followed before being routed to the operator
* `route_to_operator_search_text` used to save the last search term the user entered, before being routed to operator

## Flow results

* `emergency_help`, Get set to `yes` once the user enters the Emergency Help menu
* `emergency_numbers_requested` set to `yes` if the user requested emergency numbers
* `question_general` used to keep track of general questions asked
* `question_urgent` used to keep track of urgent questions asked
* `aaq_faq_list_helpful` used to keep track of wether aaq list (page) was helpful
* `aaq_faq_helpful` used to keep track of wether specific aaq FAQ was helpful

## Connections to other stacks

* There is a scheduled reminder stack "Topics no response followup" that gets set to run 15 minutes after the AAQ Topics List is shown, but we haven't received any input from the user
* At the end of this flow, the users get handed over to the "Intro to human agent" flow

## Global variables

The following variable(s) are set in the `settings` global dictionary

* `contentrepo_qa_token` used to auth api calls to CMS
* `working_hours_start_day`the day of the week the helpdesk opens (note days of the week starts at Sunday being 1, and Saturday being 7)
* `working_hours_end_day` the day of the week the helpdesk closes
* `working_hours_start_hour` The hour that the helpdesk opens
* `working_hours_end_hour`The hour that the helpdesk closes
* `mc_ndoh_hub_token` used to authenticate calls to AAQ via MomConnect NDOH hub
* `turn_qa_token` used to authenticate calls to the Turn instance

## Content dependencies

* `mnch_onboarding_error_handling_button`
* `plat_help_welcome_help_centre_first`
* `plat_help_welcome_help_centre_returning`
* `plat_help_medical_emergency`
* `plat_help_emergency_contact_numbers`
* `plat_help_search_myhealth_prompt`
* `plat_help_technical_issue_prompt`
* `plat_help_invalid_media_catch_all`
* `plat_help_general_catch_all`
* `plat_help_medical_emergency_secondary`
* `plat_help_faqs_topics_list`
* `plat_help_faq_topic_content`
* `plat_help_acknowledgement_positive_`
* `plat_help_acknowledgement_negative_`
* `plat_help_help_desk_entry_offline`
* `plat_help_acknowledgement_negative_`

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "i2h")
# interaction_timeout(60)

```

# FetchError

```stack
card FetchError, then: InitHelpdesk do
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

```

# Initialise Helpdesk

```stack
card InitHelpdesk, then: SetWorkingHours do
  current_date = now()
  # Add two hours for SA Time
  current_date = datetime_add(current_date, 2, "h")

  current_day = weekday(current_date)
  current_hour = hour(current_date)
  log("Current hour = @current_hour")
  opening_day = global.settings.working_hours_start_day
  closing_day = global.settings.working_hours_end_day
end

# Weekdays starts on Sunday(1) and ends on Saturday(7)
card SetWorkingHours when current_day < opening_day or current_day > closing_day,
  then: CheckWorkingHours do
  log("Helpdesk is closed on this day")
  helpdesk_open = false
  opening_hour = 00
  closing_hour = 00
end

card SetWorkingHours, then: CheckWorkingHours do
  log("Helpdesk is open on this day.  Setting up opening hours")
  opening_hour = global.settings.working_hours_start_hour
  closing_hour = global.settings.working_hours_end_hour
  log("Opening hour is @opening_hour, closing hour is @closing_hour")
end

card CheckWorkingHours when current_hour >= opening_hour and current_hour < closing_hour,
  then: CheckForNavBypass do
  helpdesk_open = true
  log("Helpdesk open at this time")
end

card CheckWorkingHours, then: CheckForNavBypass do
  helpdesk_open = false
  log("Helpdesk closed at this time")
end

```

# Check for Nav Bypass

<!-- { section: "f889a7d2-078f-4bfa-b12c-b6a0ebb756bd", x: 500, y: 48} -->

```stack
card CheckForNavBypass when contact.navbypass == "HelpCentre", then: HelpCentre do
  log("Bypassing Main Menu - Goto HelpCentre")
  update_contact(navbypass: "")
end

card CheckForNavBypass when contact.navbypass == "FAQTopicsList", then: CheckInbound do
  log("Bypassing Main Menu - Goto FAQTopicsList")
  aaq_metadata = parse_json("@contact.aaq_metadata")
  user_question = aaq_metadata.user_question
  update_contact(navbypass: "")
end

card CheckForNavBypass when contact.navbypass == "SearchMyHealth", then: SearchMyHealth do
  log("Bypassing Main Menu - Goto SearchMyHealh")
  update_contact(navbypass: "")
end

card CheckForNavBypass, then: HelpCentre do
  log("Going to HelpCentre")
end

```

# Help Centre

```stack
card HelpCentre
     when is_nil_or_empty(contact.returning_help_centre_user) or
            contact.returning_help_centre_user == false,
     then: ShowHelpCentreMenu do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_welcome_help_centre_first"]
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

  intro_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)
  update_contact(returning_help_centre_user: "true")
end

card HelpCentre when contact.returning_help_centre_user == true, then: ShowHelpCentreMenu do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_welcome_help_centre_returning"]
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

  intro_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)
end

card HelpCentre do
  log("Default Help Centre msg")
end

card ShowHelpCentreMenu, then: ShowHelpCentreMenuError do
  buttons(
    MedicalEmergency: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    TechSupport: "@button_labels[2]"
  ) do
    text("""
    @intro_msg
    """)
  end
end

card ShowHelpCentreMenuError, then: ShowHelpCentreMenuError do
  buttons(
    MedicalEmergency: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    TechSupport: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

```

# Emergency Help

```stack
card MedicalEmergency, then: MedicalEmergencyError do
  write_result("emergency_help", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_medical_emergency"]
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

  emergency_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    EmergencyNumbers: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    ChatToHealthAgent: "@button_labels[2]"
  ) do
    text("""
    @emergency_msg
    """)
  end
end

card MedicalEmergencyError, then: MedicalEmergencyError do
  buttons(
    EmergencyNumbers: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    ChatToHealthAgent: "@button_labels[2]"
  ) do
    text("""
    @button_error_text
    """)
  end
end

```

# Emergency Numbers

```stack
card EmergencyNumbers, then: EmergencyNumbersError do
  write_result("emergency_numbers_requested", "yes")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_emergency_contact_numbers"]
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

  emergency_numbers_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    ChatToHealthAgent: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("""
    @emergency_numbers_msg
    """)
  end
end

card EmergencyNumbersError, then: EmergencyNumbersError do
  buttons(
    ChatToHealthAgent: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("""
    @button_error_text
    """)
  end
end

```

# Search MyHealth

```stack
card SearchMyHealth, then: CheckInbound do
  inbound_query_type = "question"
  inbound_query_urgency = "low"
  num_inbound_attempts = 0

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_search_myhealth_prompt"]
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

  search_msg = page.body.body.text.value.message

  user_question =
    ask("""
    @search_msg
    """)

  get_latest_msg =
    get(
      "https://whatsapp-praekelt-cloud.turn.io/v1/contacts/@contact.whatsapp_id/messages",
      headers: [
        [
          "Authorization",
          "Bearer @global.settings.turn_qa_token"
        ],
        ["Accept", "application/vnd.v1+json"]
      ]
    )

  inbound_message_id = get_latest_msg.body.messages[0].id
  inbound_message_type = get_latest_msg.body.messages[0].type
  log("External message id = @inbound_message_id")
  update_contact(route_to_operator_origin: "search_myhealth")
  update_contact(route_to_operator_search_text: "@user_question")
end

```

Add markdown here

# Tech Support

```stack
card TechSupport, then: CheckInbound do
  inbound_query_type = "tech_support"
  inbound_query_urgency = "low"
  num_inbound_attempts = 0

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_technical_issue_prompt"]
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

  tech_support_msg = page.body.body.text.value.message

  user_question =
    ask("""
    @tech_support_msg
    """)

  get_latest_msg =
    get(
      "https://whatsapp-praekelt-cloud.turn.io/v1/contacts/@contact.whatsapp_id/messages",
      headers: [
        [
          "Authorization",
          "Bearer @global.settings.turn_qa_token"
        ],
        ["Accept", "application/vnd.v1+json"]
      ]
    )

  inbound_message_id = get_latest_msg.body.messages[0].id
  inbound_message_type = get_latest_msg.body.messages[0].type
  log("External message id = @inbound_message_id")
  log("External message type = @inbound_message_type")
  update_contact(route_to_operator_origin: "tech_support")
  update_contact(route_to_operator_search_text: "@user_question")
end

```

# Call AAQ API and Route Results

```stack
card CheckInbound when num_inbound_attempts > 1 and helpdesk_open == true, then: SendToHelpdesk do
  log("Too many failed attempts (@num_inbound_attempts), Helpdesk is open, routing there")
  update_contact(route_to_operator_origin: "failed_attempts")
end

card CheckInbound
     when user_question == "image" or user_question == "audio" or user_question == "video" or
            user_question == "document",
     then: NonTextDetected do
  num_inbound_attempts = num_inbound_attempts + 1
  log("Non text input found. Setting num_inbound_attempts = @num_inbound_attempts")
end

card CheckInbound, then: RouteResults do
  inbound_result =
    post(
      "https://hub.qa.momconnect.co.za/api/v1/inbound/check",
      body: """
        {"question": "@user_question"}
      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  inbound_id = inbound_result.body.inbound_id
  body = inbound_result.body.body
  inbound_secret_key = inbound_result.body.inbound_secret_key
  feedback_secret_key = inbound_result.body.feedback_secret_key
  faq_topic_list = inbound_result.body.message

  # TODO: See if there is a cleaner way of doing this
  faq_topic_list = substitute("@faq_topic_list", "*1* -", "1.")
  faq_topic_list = substitute("@faq_topic_list", "*2* -", "2.")
  faq_topic_list = substitute("@faq_topic_list", "*3* -", "3.")
  faq_topic_list = substitute("@faq_topic_list", "*4* -", "4.")
  faq_topic_list = substitute("@faq_topic_list", "*5* -", "5.")
end

card RouteResults when faq_topic_list == "Gibberish Detected", then: GibberishDetected do
  num_inbound_attempts = num_inbound_attempts + 1
  log("Routing results as gibberish. Num failed attempts = @num_inbound_attempts")
end

card RouteResults when faq_topic_list == "Non-text Input Detected", then: NonTextDetected do
  num_inbound_attempts = num_inbound_attempts + 1
  log("Routing results as non-text. Num failed attempts = @num_inbound_attempts")
end

card RouteResults when body != "", then: CheckUrgency do
  log("Body is not blank")
end

card RouteResults do
  log("Routing results default")
end

```

# Gibberish/ Non-text detected

```stack
card NonTextDetected, then: CheckInbound do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_invalid_media_catch_all"]
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

  non_text_msg = page.body.body.text.value.message

  user_question =
    ask("""
    @non_text_msg
    """)
end

card GibberishDetected, then: CheckInbound do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_general_catch_all"]
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

  gibberish_msg = page.body.body.text.value.message

  user_question =
    ask("""
    @gibberish_msg
    """)
end

```

# Check Urgency

```stack
card CheckUrgency, then: RouteUrgency do
  urgency_result =
    post(
      "https://hub.qa.momconnect.co.za/api/v1/check-urgency",
      body: """
        {"question": "@user_question"}
      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  # Note on urgency score. 0.0 for not urgent, 1.0 for urgent
  urgency_score = urgency_result.body.urgency_score
end

card RouteUrgency when urgency_score == 0.0, then: DisplayFAQTopicsList do
  log("Not Urgent - @urgency_score")
  inbound_query_urgency = "low"
  write_result("question_general", "@user_question")
end

card RouteUrgency when urgency_score == 1.0, then: RouteUrgencyError do
  log("Urgent - @urgency_score")
  inbound_query_urgency = "high"
  write_result("question_urgent", "@user_question")

  attach_label_result =
    post(
      "https://whatsapp-praekelt-cloud.turn.io/v1/messages/@inbound_message_id/labels",
      body: """
      {
        "labels": ["urgent"]
      }
      """,
      headers: [
        [
          "Authorization",
          "Bearer @global.settings.turn_qa_token"
        ],
        ["content-type", "application/json"],
        ["Accept", "application/vnd.v1+json"]
      ]
    )

  log("Attach Label Result = @attach_label_result")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_medical_emergency_secondary"]
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

  urgent_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    EmergencyNumbers: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]"
  ) do
    text("@urgent_msg")
  end
end

card RouteUrgency do
  log("Default RouteUrgency")
end

card RouteUrgencyError, then: RouteUrgencyError do
  log("Default RouteUrgency")

  buttons(
    EmergencyNumbers: "@button_labels[0]",
    SearchMyHealth: "@button_labels[1]"
  ) do
    text("@button_error_text")
  end
end

```

# FAQ Topics List

```stack
card DisplayFAQTopicsList, then: ValidateFAQSelection do
  # Set these values to a contact field so we can route back to the results page from other stacks
  json_values =
    parse_json("""
      {
        "inbound_id": "@inbound_id", 
        "feedback_secret_key": "@feedback_secret_key",
        "user_question": "@user_question"
      }
    """)

  update_contact(aaq_metadata: "@json(json_values)")

  schedule_stack("988b513e-8063-4f2c-821c-94e75536f09f", in: 900)

  log(
    "Scheduled stack `HC: Scheduled - Topics No Response followup - 988b513e-8063-4f2c-821c-94e75536f09f` to run in 15 minutes"
  )

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_faqs_topics_list"]
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

  topic_list_msg = page.body.body.text.value.message
  substituted_msg = substitute(topic_list_msg, "{faq_topic_list}", "@faq_topic_list")

  selected_faq =
    ask("@substituted_msg")
end

card ValidateFAQSelection when not has_pattern("@selected_faq", "^\d+$"),
  then: ValidateFAQSelectionError do
  log("Non-integer selection")
end

card ValidateFAQSelection when selected_faq > 0 and selected_faq < 6, then: DisplayFAQ do
  log("Get FAQ Article")
  cancel_scheduled_stacks("988b513e-8063-4f2c-821c-94e75536f09f")

  log(
    "Valid FAQ Topic List input received. Cancelling previously scheduled stack `HC: Scheduled - Topics no response follow-up - 988b513e-8063-4f2c-821c-94e75536f09f`"
  )
end

card ValidateFAQSelection when selected_faq > 6, then: ValidateFAQSelectionError do
  log("Number higher than 6")
end

card ValidateFAQSelection when selected_faq == 6, then: SendToHelpdesk do
  log("None helpful on page")
  cancel_scheduled_stacks("988b513e-8063-4f2c-821c-94e75536f09f")

  log(
    "Valid FAQ Topic List input received. Cancelling previously scheduled stack `HC: Scheduled - Topics no response follow-up - 988b513e-8063-4f2c-821c-94e75536f09f`"
  )

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
end

card ValidateFAQSelectionError, then: ValidateFAQSelection do
  log("Error on  RouteFAQSelection")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_faqs_topics_list_error"]
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

  topic_list_error_msg = page.body.body.text.value.message

  selected_faq =
    ask("@topic_list_error_msg")
end

```

# Display FAQ

```stack
card DisplayFAQ, then: DisplayFAQError do
  log("DisplayFAQ")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_faq_topic_content"]
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

  display_faq_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)
  text("@body['@selected_faq'].text")

  buttons(
    FaqWasHelpful: "@button_labels[0]",
    FaqWasNotHelpful: "@button_labels[1]"
  ) do
    text("@display_faq_msg")
  end
end

card DisplayFAQError, then: DisplayFAQError do
  buttons(
    FaqWasHelpful: "@button_labels[0]",
    FaqWasNotHelpful: "@button_labels[1]"
  ) do
    text("""
    @button_error_text
    """)
  end
end

```

# Send AAQ Feedback

```stack
card FaqWasHelpful, then: AcknowledgePositive do
  log("FaqWasHelpful")
  write_result("aaq_faq_helpful", "yes")

  feedback_result =
    put(
      "https://hub.qa.momconnect.co.za/api/v1/inbound/feedback",
      body: """
      {
        "feedback_secret_key": "@feedback_secret_key",
        "inbound_id": "@inbound_id",
        "feedback": {
          "feedback_type": "positive",
          "faq_id": "@body['@selected_faq'].id"
        }
      }

      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  log("Feedback result = @feedback_result")
end

card FaqWasNotHelpful, then: AcknowledgeNegative do
  log("FaqWasNotHelpful")
  write_result("aaq_faq_helpful", "no")

  feedback_result =
    put(
      "https://hub.qa.momconnect.co.za/api/v1/inbound/feedback",
      body: """
      {
        "feedback_secret_key": "@feedback_secret_key",
        "inbound_id": "@inbound_id",
        "feedback": {
          "feedback_type": "negative",
          "faq_id": "@body['@selected_faq'].id"
        }
      }

      """,
      headers: [
        ["Authorization", "Token @global.settings.mc_ndoh_hub_token"],
        ["content-type", "application/json"]
      ]
    )

  log("Feedback result = @feedback_result")
end

card AcknowledgePositive do
  log("AcknowledgePositive")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_acknowledgement_positive_"]
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

  ack_pos_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    RouteUrgency: "@button_labels[0]",
    HelpCentre: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("@ack_pos_msg")
  end
end

card AcknowledgePositiveError, then: AcknowledgePositiveError do
  buttons(
    RouteUrgency: "@button_labels[0]",
    HelpCentre: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("@button_error_text")
  end
end

card AcknowledgeNegative, then: RouteUrgency do
  log("AcknowledgeNegative")

  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_acknowledgement_negative_"]
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

  ack_neg_msg = page.body.body.text.value.message
  text("@ack_neg_msg")
end

```

# Send to Helpdesk

```stack
card SendToHelpdesk, then: CheckHelpdeskStatus do
  # Attach the relevant labels to the chat
  log("Query urgency is @inbound_query_urgency")
  log("Query type label to attach is @inbound_query_type")
  log("External ID of msg to label  = @inbound_message_id")
end

card CheckHelpdeskStatus when helpdesk_open == true, then: HelpdeskOpen do
  log("Helpdesk status is open")
end

card CheckHelpdeskStatus, then: HelpdeskClosed do
  log("Helpdesk status is closed")
end

card HelpdeskOpen do
  attach_label_result =
    post(
      "https://whatsapp-praekelt-cloud.turn.io/v1/messages/@inbound_message_id/labels",
      body: """
      {
        "labels": ["@inbound_query_type"]
      }
      """,
      headers: [
        [
          "Authorization",
          "Bearer @global.settings.turn_qa_token"
        ],
        ["content-type", "application/json"],
        ["Accept", "application/vnd.v1+json"]
      ]
    )

  log("Attach Label Result = @attach_label_result")
  run_stack("8046066f-3cb1-43d6-ace0-850769bd13a3")
end

card HelpdeskClosed, then: HelpdeskClosedError do
  search =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/",
      query: [
        ["slug", "plat_help_help_desk_entry_offline"]
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

  closed_msg = page.body.body.text.value.message
  button_labels = map(page.body.body.text.value.buttons, & &1.value.title)

  buttons(
    HelpCentre: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("""
    @closed_msg
    """)
  end
end

card HelpdeskClosedError, then: HelpdeskClosedError do
  buttons(
    HelpCentre: "@button_labels[0]",
    TopicsForYou: "@button_labels[1]",
    HelpCentre: "@button_labels[2]"
  ) do
    text("""
    @button_error_text
    """)
  end
end

```

# Chat to health agent

```stack
card ChatToHealthAgent when helpdesk_open == true do
  log("Setting route_to_operator_origin to 'emergency'")
  update_contact(route_to_operator_origin: "emergency")
  run_stack("8046066f-3cb1-43d6-ace0-850769bd13a3")
end

card ChatToHealthAgent, then: HelpdeskClosed do
  log("Helpdesk closed, directing to message")
end

card BypassUrgency, then: SendToHelpdesk do
  # cancel_scheduled_stacks("798c43ff-abde-44a6-871b-f9a3729e9dd9")
  add_label("Urgent")
  log("Bypassing urgency check and sending to helpdesk")
end

```

# Still to be fleshed out

```stack
card YourHealthGuide do
  text("Still to be fleshed out.  I am YourHealthGuide")
end

card TopicsForYou do
  text("Still to be fleshed out. I am TopicsForYou")
end

card ManageUpdates do
  text("Still to be fleshed out. I am ManageUpdates")
end

card YourProfile do
  text("Still to be fleshed out. I am YourProfile")
end

card ManageData do
  text("Still to be fleshed out. I am ManageData")
end

card AboutAndPrivacy do
  text("Still to be fleshed out. I am AboutAndPrivacy")
end

card TalkToACouncellor do
  text("Still to be fleshed out. I am TalkToACouncellor")
end

card TakeATour do
  text("Still to be fleshed out. I am TakeATour")
end

```

Add markdown here