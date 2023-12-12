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
  timestamp = datetime_add("@contact[contact_field]", offset, unit)
  date = date(year(timestamp), month(timestamp), day(timestamp))
end

card GetMessage when date == today(), then: SendMessage do
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

card GetMessage, then: CalculateTimestamp do
  page = page + 1
end

card SendMessage when page.body.is_whatsapp_template do
  send_message_template("@lower(page.body.whatsapp_template_name)", "en_US", ["@contact.name"],
    buttons: [Button1, Button2, Button3]
  )
end

card SendMessage do
  text("TODO: send normal message")
end

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
