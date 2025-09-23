This stack fetches the current message for the current message set, as defined in the contact fields.

It handles the following message types:

* Template messages. Assumes template message with two variables. Sets the first to the contact's whatsapp profile name, and the second to the literal "Second"
* Text messages. Sends the title, followed by the body, of the whatsapp message, in a single message to the user.

It then increments the content set position on the contact, and runs the stack that handles scheduling the next message in the message set.

## Configuration

This Journey requires the `config.contentrepo_token` global variable to be set.

## Contact fields

* push_messaging_content_set_position: Start at 0, to always start at the beginning of the message set
* whatsapp_profile_name, used to personalise the template sent to the user

## Flow results

* message_sent, The message sent to the user

## Connections to other stacks

* Runs the stack to schedule the next push message at the end

<!-- { section: "c1af92c3-f489-4f4b-8182-865897f83ea1", x: 0, y: 0} -->

```stack
card GetMessage, then: SendMessage do
  contentset =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/orderedcontent/@contact.push_messaging_content_set/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  contentset_item = contentset.body.pages[contact.push_messaging_content_set_position]

  page =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@contentset_item.id/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["sms", "true"]]
    )
end

card SendMessage when page.body.body.is_whatsapp_template, then: ScheduleNextMessage do
  write_result("template_sent", "@page.body.body.whatsapp_template_name")

  send_message_template("@page.body.body.whatsapp_template_name", "en_US", [
    "@contact.whatsapp_profile_name",
    "Second"
  ])
end

card SendMessage, then: ScheduleNextMessage do
  write_result("message_sent", "@page.body.id")

  # This changes between here and the OG Whatsapp Flow
  update_contact(route_to_journey: "sbm")

  text("""
  @page.body.body.text.message
  """)
end

card ScheduleNextMessage do
  update_contact(
    push_messaging_content_set_position: "@(contact.push_messaging_content_set_position + 1)"
  )

  # SBM: Schedule next push message
  run_stack("fac94d2c-682f-4fea-8b7b-ab284a26d311")
end

```