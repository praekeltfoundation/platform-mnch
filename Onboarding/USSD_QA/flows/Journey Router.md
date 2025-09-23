# Router

This is the main router for this Channel. When an SMS is sent on the SMS channel, it updates a contact field, which is synced to this channel. Then when the user dials into the USSD line, we check that contact field to know which journey they should be sent on.

```stack
trigger(on: "MESSAGE RECEIVED") when has_any_exact_phrase(event.message.text.body, ["0", "hi"])

```

```stack
card Menu, then: HandleOption do
  option = ask("Welcome to Reach Digital. What would you like to do?
  
  1. Register for Re-Engagement
  2. Register for Stage Based Messaging
  3. Take me to the content")
end

card HandleOption when option == "1" do
  # Re-Engagement
  update_contact(registration_started: "@now()")
  update_contact(registration_status: "started")

  text("Registration @contact.registration_status")
end

card HandleOption when option == "2" do
  # SBM
  # Fetch Content
  contentsets =
    get(
      "https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/orderedcontent/",
      headers: [
        ["Authorization", "Token @global.config.contentrepo_token"]
      ],
      query: [["slug", "sbm-demo"]]
    )

  contentset = contentsets.body.results[0]

  write_result("sbm_signup", "@contentset.id")
  update_contact(push_messaging_signup_time: "@now()")
  update_contact(push_messaging_content_set: "@contentset.id")
  update_contact(push_messaging_content_set_position: 0)
  text("Thank you for signing up! You will receive your first message shortly")
end

card HandleOption when option == "3" do
  then(Router)
end

card HandleOption do
  then(Menu)
end

```

# Router

This section routes to the correct stack depending on the `route_to_journey` contact field.

<!-- { section: "ef4ebe3e-5431-460e-8017-2dfd2a8aaec7", x: 0, y: 0} -->

```stack
card Router when contact.route_to_journey == "sbm" do
  run_stack("c151e915-7070-4682-a101-82824954a12f")
end

card Router when contact.route_to_journey == "dma" do
  run_stack("75acc332-9d46-4a92-baf8-ae3ebf8448c2")
end

card Router do
  # Default - no route found - run DMA - TODO: This should probably change to a menu when we get there.
  log("No route found on contact: @contact.route_to_journey. Routing to DMA.")

  run_stack("75acc332-9d46-4a92-baf8-ae3ebf8448c2")
end

```