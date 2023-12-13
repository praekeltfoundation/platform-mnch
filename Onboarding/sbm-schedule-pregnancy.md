# SBM: Schedule pregnancy

This stack looks for a content set named "Pregnancy", and uses the schedule defined in that content set.

It deletes all schedules for "SBM: Send pregnancy message", and then goes through and creates a schedule for each message defined in the content set.

It will skip any message whose calculated send time would be in the past.

It ignores time information, focusing just on the date, and schedules each message to be sent at 9am SAST.

## Contact fields

This flow does not update any contact fields

## Flow results

This flow does not save any flow results

## Connections to other stacks

This flow schedules the "SBM: Send pregnancy message" stack to be run according to the schedule defined in the "Pregnancy" content set.

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

<!-- { section: "09a3c71d-8d59-4202-9276-7333f5e9e1bf", x: 0, y: 0} -->

```stack
card GetContentSet, then: CalculateTimestamp do
  # Cancel all previously scheduled stacks for pregnancy
  cancel_scheduled_stacks("e323943a-b48e-495d-b0e2-e9349c58f854")

  contentsets =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/orderedcontent/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  contentset = find(contentsets.body.results, &(&1.name == "Pregnancy"))

  contentset =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/orderedcontent/@contentset.id/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  contentset = contentset.body
  page = 0
end

card CalculateTimestamp when page == count(contentset.pages) do
  log("No more pages")
end

card CalculateTimestamp, then: SchedulePage do
  details = contentset.pages[page]
  contact_field = details.contact_field

  unit =
    find(
      [["minutes", "m"], ["hours", "h"], ["days", "D"], ["months", "M"]],
      &(&1[0] == details.unit)
    )[1]

  offset = if(details.before_or_after == "before", details.time * -1, details.time * 1)
  timestamp = datetime_add("@contact[contact_field]", offset, unit)
  # 7am UTC == 9am SAST
  timestamp = datetime_add(date(year(timestamp), month(timestamp), day(timestamp)), 7, "h")
end

card SchedulePage when timestamp <= now(), then: CalculateTimestamp do
  log("skipping page @page, in the past @timestamp")
  page = page + 1
end

card SchedulePage, then: CalculateTimestamp do
  # TODO: This is temporary to allow easy testing, remove for production use
  text("Scheduling page @contentset.pages[page].title at @timestamp")
  schedule_stack("e2641356-9511-4211-8e3c-5e9ae251127b", at: timestamp)
  page = page + 1
end

```
