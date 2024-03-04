# SBM: Send pregnancy message

This stack gets called according to the message sending schedule

It's responsible for finding out what message should be sent at this moment, and then sending it.

It looks for a content set with the name "Pregnancy", and then goes through each of the items on the content set, calculating when each should be sent, until it finds one that matches today's date. It then looks up the message details, and sends the template, assuming that there's one variable for the user's name, and 3 buttons.

## Contact fields

This stack does not update any contact fields

## Flow results

This stack does not save any flow results

## Connections to other stacks

This stack does not call any other stacks

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key               | Value                                    |
| ----------------- | ---------------------------------------- |
| contentrepo_token | xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx |

# Steps

1. Get the Pregnancy ordered content set
2. Loop through all the pages in it
3. If page is NOT today, Ignore it, but get next page
4. If page = today, send it
5. Exit

# Debug notes

EDD is set as 2024-04-09
5 weeks before EDD is 5 March
4 weeks before EDD is 12 March

<!-- { section: "ee62614a-95eb-4e52-8ede-b2ddbea826d2", x: 0, y: 0} -->

```stack
card GetContentSet, then: CalculateTimestamp do
  contentsets =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/orderedcontent/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  contentset = find(contentsets.body.results, &(&1.name == "Pregnancy"))
  contentset_name = @contentset.name

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
  log("Cannot find page for today's send")
end

card CalculateTimestamp, then: GetMessage do
  details = contentset.pages[page]
  contact_field = details.contact_field

  unit =
    find(
      [["minutes", "m"], ["hours", "h"], ["days", "D"], ["months", "M"]],
      &(&1[0] == details.unit)
    )[1]

  offset = if(details.before_or_after == "before", details.time * -1, details.time * 1)
  schedule_timestamp = datetime_add("@contact['edd']", offset, unit)

  schedule_date =
    date(year(schedule_timestamp), month(schedule_timestamp), day(schedule_timestamp))
end

card GetMessage when schedule_date == today(), then: SendMessage do
  page = contentset.pages[page]

  page =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/pages/@page.id/",
      query: [["whatsapp", "true"]],
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  page = page.body
end

card GetMessage when schedule_date != today(), then: CalculateTimestamp do
  page = page + 1
end

card GetMessage, then: CalculateTimestamp do
  page = page + 1
end

card SendMessage when page.body.is_whatsapp_template, then: CheckContentSetMaxID do
  page_id = @page.id

  send_message_template(
    "@lower(page.body.whatsapp_template_name)",
    "en_US",
    ["@contact['whatsapp_profile_name']"],
    buttons: [Button1, Button2, Button3]
  )

  update_contact(pages_seen: "@contact['pages_seen'] @page.meta.slug,")
end

```

```stack
card CheckContentSetMaxID, then: GetMaxID do
  log("CheckContentSetMaxID")

  contentsets =
    get(
      "https://platform-mnch-contentrepo.prk-k8s.prd-p6t.org/api/v2/orderedcontent/",
      headers: [
        ["Authorization", "Token @config.items.contentrepo_token"]
      ]
    )

  contentset = find(contentsets.body.results, &(&1.name == "Pregnancy"))

  contentset_name = @contentset.name

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

card GetMaxID when page == count(contentset.pages), then: UpdateContentCompleted do
  log("Reached last content set")
  max_id = @details.id
end

card GetMaxID, then: FetchPage do
  log("GetMaxID")
  details = contentset.pages[page]
end

card FetchPage, then: GetMaxID do
  log("Fetchpage")
  details = contentset.pages[page]
  page = page + 1
end

card UpdateContentCompleted when page_id == max_id do
  log("UpdateContentCompleted")
  update_contact(content_completed: "@contact['content_completed'] @contentset_name,")
end

```

```stack
card Button1 do
  text("TODO: Template button actions")
end

card Button2 do
  text("TODO: Template button actions")
end

card Button3 do
  text("TODO: Template button actions")
end

```