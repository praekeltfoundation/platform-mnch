<!-- { section: "1b56a5ae-3fd7-4a45-a490-6b60e0f2fef3", x: 0, y: 0} -->

```stack
trigger(on: "MESSAGE RECEIVED", global: true)
when has_only_phrase(event.message.text.body, "hello")

```

<!-- { section: "66fcf2f8-8641-4392-9b32-bbc9270bb5ac", x: 500, y: 0} -->

```stack
card Text_1, "Text_1",
  version: "1",
  uuid: "dc24ea0d-8f6e-514c-aaf9-c1a4d79c9898",
  code_generator: "TEXT_MESSAGE" do
  text("Is it me you're looking for?")
  then(Profile_1)
end

```

<!-- { section: "bd5601c5-c487-43d9-89c1-e40cbafb25d0", x: 988, y: 0} -->

```stack
card Profile_1, "Profile_1",
  version: "1",
  uuid: "3360cf97-31b0-4a3a-9a64-db493c8e221e",
  code_generator: "UPDATE_CONTACT" do
  update_contact(name: "Bobbo")
end

```

<!-- { section: "cf50f2b0-b60d-436f-89a1-5e8caecb6cc5", x: -1000, y: 0} -->

```stack
card RESERVED_DEFAULT_CARD, "RESERVED_DEFAULT_CARD", code_generator: "RESERVED_DEFAULT_CARD" do
  # RESERVED_DEFAULT_CARD
end

```

<!-- { section: "INTERACTION_TIMEOUT_CELL", x: 0, y: 0} -->

```stack
interaction_timeout(300)

```