```stack
trigger(on: "MESSAGE RECEIVED")
when has_phrase(event.message.text.body, "reengageregister")

```

<!-- { section: "1b3436c9-e6d6-45a9-84d5-a43d568de845", x: 0, y: 0} -->

```stack
card TextMessage do
  update_contact(registration_started: "@now()")
  update_contact(registration_status: "started")

  text("Registration @contact.registration_status")
end

```