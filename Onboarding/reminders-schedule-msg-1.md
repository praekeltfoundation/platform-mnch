# Onboarding: Schedule Reminder Msg #1

This stack schedules a re-engagement reminder for part 2 of the onboarding flows.  This is just an example put in place while the reminder flows are still in design.

You can set the `time_offset` and `time_unit` by updating the values in the `Values` column in the `config` dictionary below.

The `time_unit` can be any of the following values:

* `"Y" for years`
* `"M" for months`
* `"W" for weeks`
* `"D" for days`
* `"h" for hours`
* `"m" for minutes`
* `"s" for seconds`

For now we have it set as 2 minutes for testing purposes.

## Connections to other stacks

* Schedules the `Onboarding: Send Reminder Message #1` stack to be run at the given `time_unit` and `time_offset`

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key         | Value |
| ----------- | ----- |
| time_offset | 2     |
| time_unit   | m     |

<!-- { section: "18c862f9-d5ed-4b05-9c6d-cf725635f238", x: 0, y: 0} -->

```stack
# Note : 7am UTC == 9am SAST

card Setup, then: ScheduleReminder do
  # Cancel any previous scheduled instance of this stack
  cancel_scheduled_stacks("b93ddac0-5a3d-42a1-af01-5bbc865ef389")
  time_offset = "@config.items.time_offset"
  time_unit = "@config.items.time_unit"
  timestamp = datetime_add(now(), time_offset, "@time_unit")
end

card ScheduleReminder do
  log("Scheduling Re-engagement reminder #1 at @timestamp ")
  schedule_stack("415a57c3-2755-4632-9477-56df0fb049f5", at: timestamp)
end

```