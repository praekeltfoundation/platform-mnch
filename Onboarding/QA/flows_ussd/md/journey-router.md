# Router

This is the main router for this Channel. When an SMS is sent on the SMS channel, it updates a contact field, which is synced to this channel. Then when the user dials into the USSD line, we check that contact field to know which journey they should be sent on.

```stack
trigger(on: "MESSAGE RECEIVED") when has_any_exact_phrase(event.message.text.body, ["0", "hi"])

```

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