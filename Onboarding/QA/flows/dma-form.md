<!-- { section: "2006d644-d5eb-4b63-9de1-bfc8d1eebc1f", x: 500, y: 48} -->

```stack
trigger(on: "MESSAGE RECEIVED") when has_only_phrase(event.message.text.body, "tform")

```

# Forms

This journey consolidates the various form question types in a single journey.

It will fetch the form specified by the configured slug from ContentRepo, and run the user through the questions with type validations.

The values are set in the form.

This journey writes the user's answers to the flow results.

## Content fields

This Journey does not write to any contact fields. Unless it's necessary for the particular implementation, it's best that this journey doesn't write any contact fields.

## Flow results

* `assessment_start` - writes the slug of the started assessment when the assessment run starts
* `question_num` - the number of the question being answered
* `answer` - the answer that the user chose
* `min` - the lower bound (minimum value that the number can be)
* `max` - the upper bound (maximum value that the number can be)
* `assessment_end` - writes the slug of the assessment when the assessment run ends
* `assessment_score`, the score that the user got for this run of the assessment
* `max_assessment_score`, the maximum score possible for this user for this run of the assessment

## Substitution

The journey uses substitution so the error messages are more specific.
  {min} and {max} in the form are replaced with the minimum and maximum range values.
  {current_year} and {lower_bound} in the form are replaced with current calendar year and lower bound valid year.

## Connections to other Journeys

This Journey does not link to any other Journeys

## Explainer keywords

"why", "wy", "wh", "explain", "expain", "eplain"

<!--
 dictionary: "config"
version: "0.1.0"
columns: [] 
-->

| Key            | Value    |
| -------------- | -------- |
| assessment_tag | dma_form |

## Get Assessment

We fetch the assessment as configured in the assessment_tag. At this point we initialise the following variables used throughout the Journey:

* `questions`, the questions to be asked in the form
* `locale`, the locale of the form
* `question_num`, the current question number
* `score`, the total assessment score, used at the end to determine which page to show the user
* `keywords`, the keywords that will trigger the explainer text

We also write the follwing flow results:

* `assessment_start`, the assessment tag
* `locale`, the locale of the form

<!-- { section: "c8467498-ead8-42c0-a1a8-e37d85ac349a", x: 0, y: 0} -->

```stack
card GetAssessment, then: CheckEnd do
  log("Fetching assessment @config.items.assessment_tag")

  response =
    get("https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/assessment/",
      timeout: 5_000,
      cache_ttl: 60_000,
      query: [
        # TODO: Remove hard coding when flow tester gets support for dicts
        ["tag", "dma_form"]
      ],
      headers: [
        ["content-type", "application/json"],
        ["authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  assessment_data = response.body.results[0]
  questions = assessment_data["questions"]
  locale = assessment_data["locale"]
  slug = assessment_data["slug"]
  version = assessment_data["version"]
  question_num = 0
  score = 0
  min = 0
  max = 0
  assertion = ""
  get_today = today()
  get_year = year(get_today)
  range = 120
  max_score = 0
  skip_count = 0
  skip_threshold = assessment_data["skip_threshold"]

  # A user can respond with a keyword such as "why" or "explain" to
  # know the reason why we asked a question. 
  # We store a list of possible keyword iterations to handle typos
  keywords = ["why", "wy", "wh", "explain", "expain", "eplain"]

  log("Starting assessment @config.items.assessment_tag")
  write_result("version", "@version")
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_started", "yes")
  write_result("locale", "@locale")
end

```

## Display Question & Validation

1. Check if the current question is the last question
   1. If yes record the results
      * `assessment_end`, the assessment tag
      * `assessment_score`, the final score of the assessment
2. Get the question from the API response
3. Replace any variables in the question that need to be replaced
4. Display the question
5. Validate the answer and / or explain the reason for the question
6. Repeat until we reach the last question

```stack
card CheckEnd when question_num == count(questions), then: End do
  # Because all of the guards for a card get evaluated at the same time, we have to first check if we
  # have any more questions, before we can assume that there's a question that we can access the
  # attributes of, and we have to do this in a separate CheckEnd card before the DisplayQuestion card

  # workaround because the percentage calculation will throw a division by 0 error if max_score is 0 in either an if or a when clause.
  score_perc = score / max(max_score, 1) * 100
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_completed", "yes")
end

card CheckEnd do
  then(GetQuestion)
end

card GetQuestion, then: DisplayQuestion do
  question = questions[question_num]
  question_text = question.question

  # Any variable replacement required can happen here
  name = if(is_nil_or_empty(contact.name), do: "", else: contact.name)
  question_text = substitute(question_text, "{{name}}", "@name")
end

card DisplayQuestion when questions[question_num].question_type == "multiselect_question",
  then: DisplayMultiselectAnswer do
  # Display the Multiselect Question type
  answer_num = 0
  multiselect_answer = ""
  scores = map(question.answers, & &1.score)
  max_question_score = reduce(scores, 0, &(&1 + &2))
  max_score = max_score + max_question_score
end

card DisplayQuestion when count(questions[question_num].answers) > 3, then: QuestionExplainer do
  # For more than 3 options, use a list
  question = questions[question_num]

  question_response =
    list("Select option", QuestionResponse, map(question.answers, &[&1.answer, &1.answer])) do
      text("@question_text")
    end
end

card DisplayQuestion when questions[question_num].question_type == "year_of_birth_question",
  then: QuestionExplainer do
  # Display the Year of Birth Question type
  question = questions[question_num]

  question_response = ask("@question_text")
  difference = get_year - question_response

  assertion =
    has_number("@question_response") and has_number_lte("@question_response", "@get_year") and
      has_number_lte("@difference", "@range") and has_pattern("@question_response", "^[0-9]+$")
end

card DisplayQuestion when questions[question_num].question_type == "freetext_question",
  then: QuestionExplainer do
  # Display the freetext Question type
  question = questions[question_num]

  question_response = ask("@question_text")
end

card DisplayQuestion when questions[question_num].question_type == "integer_question",
  then: QuestionExplainer do
  # Display the Integer Question type
  question = questions[question_num]

  question_response = ask("@question_text")
  min = questions[question_num].min
  max = questions[question_num].max

  assertion =
    has_number("@question_response") and has_number_gte("@question_response", "@min") and
      has_number_lte("@question_response", "@max")
end

card DisplayQuestion when questions[question_num].question_type == "age_question",
  then: ValidateAge do
  # Display the Age Question type
  question = questions[question_num]

  question_response = ask("@question_text")
end

card DisplayQuestion, then: QuestionExplainer do
  # For up to 3 options, use buttons 
  question = questions[question_num]

  question_response =
    buttons(QuestionResponse, map(question.answers, &[&1.answer, &1.answer])) do
      text("@question_text")
    end
end

card ValidateAge when has_all_members(keywords, [@question_response]) == true,
  then: AgeExplainer do
  log("Explainer returned for age question")
end

card ValidateAge when not isnumber(question_response) or question_response > 150,
  then: QuestionError do
  log("Validatation failed for age question")
end

card ValidateAge, then: QuestionResponse do
  log("Validation suceeded for age question")
end

card AgeExplainer, then: GetQuestion do
  explainer =
    if(
      is_nil_or_empty(question.explainer),
      "*Explainer:* There's no explainer for this.",
      concatenate("*Explainer:*", " ", question.explainer)
    )

  text("@explainer")
end

card QuestionExplainer when has_all_members(keywords, [@question_response]), then: GetQuestion do
  explainer =
    if(
      is_nil_or_empty(question.explainer),
      "*Explainer:* There's no explainer for this.",
      concatenate("*Explainer:*", " ", question.explainer)
    )

  text("@explainer")
end

card QuestionExplainer, then: ValidateInput do
  type = questions[question_num].question_type
  log("Question type is @type")
  log("Your answer was @question_response to question number @question_num")
end

card ValidateInput
     when assertion == false and questions[question_num].question_type == "year_of_birth_question",
     then: QuestionError do
  log("Error input")
end

card ValidateInput
     when assertion == false and questions[question_num].question_type == "integer_question",
     then: QuestionError do
  log("Error input")
end

card ValidateInput
     when count(question.answers) > 0 and
            not has_member(map(question.answers, & &1.answer), question_response),
     then: QuestionError do
  log("Invalid input")
end

card ValidateInput, then: QuestionResponse do
  log("Valid input")
end

card QuestionError
     when questions[question_num].question_type == "integer_question" and
            @question_response != lower("skip"),
     then: CheckEnd do
  log(
    "Invalid input for integer_question: @question_response. Required value between @min and @max."
  )

  # If we have an error for this question, then use that, otherwise use the generic one
  error = if(is_nil_or_empty(question.error), assessment_data.generic_error, question.error)
  type = questions[question_num].question_type
  replace_min = substitute("@error", "{min}", "@min")
  substituted_text = substitute("@replace_min", "{max}", "@max")
  styled_error = concatenate("*Error:*", " ", "@substituted_text")
  text("@styled_error")
end

card QuestionError
     when questions[question_num].question_type == "year_of_birth_question" and
            @question_response != lower("skip"),
     then: CheckEnd do
  log(
    "Invalid input for year_of_birth_question: @question_response. Required value between @lower_bound_year and @get_year"
  )

  # If we have an error for this question, then use that, otherwise use the generic one
  error = if(is_nil_or_empty(question.error), assessment_data.generic_error, question.error)
  type = questions[question_num].question_type
  lower_bound_year = get_year - range
  log("get_year is @get_year and difference is @difference")
  replace_current_year = substitute("@error", "{current_year}", "@get_year")
  substituted_text = substitute("@replace_current_year", "{lower_bound}", "@lower_bound_year")
  styled_error = concatenate("*Error:*", " ", "@substituted_text")
  text("@styled_error")
end

card QuestionError when has_all_members(keywords, [@question_response]), then: CheckEnd do
  explainer =
    if(
      is_nil_or_empty(question.explainer),
      "*Explainer:* There's no explainer for this.",
      concatenate("*Explainer:*", " ", question.explainer)
    )

  text("@explainer")
end

card QuestionError when @question_response == lower("skip"), then: StoreResponse do
  # If they skip a question we should 
  # - record the answer as "skip"
  # - increment skip count
  # - do not count the question towards the score
  # - do not add the max score for this question (i.e. completely exclude this question from scoring)
  question_id = questions[question_num].semantic_id
  skip_count = skip_count + 1

  log("Skipping question @question_num")
  log("Current score: @score, Current max score: @max_score")

  question_num = question_num + 1
end

card QuestionError, then: CheckEnd do
  # If we have an error for this question, then use that, otherwise use the generic one
  error = if(is_nil_or_empty(question.error), assessment_data.generic_error, question.error)
  log("Question number is @question_num")
  log("You entered @question_response")
  text("@error")
end

```

## Multiselect Question

Multiselect gets a block on its own because it's essentially questions in a question. For multiselect, until we are able to use a checkbox-style input, we ask the question once for each answer that was configured, and ask the user to select `Yes`, or `No` for each answer.

The basic idea for the multiselect question is very similar to how we display questions.

1. Check if this is the last multiselect answer
   1. If yes, record the results
      * `question_num`, the question number
      * `answer`, the final answer which will be a comma separated list of all the answers that were selected
2. Get the next answer
3. Concatenate the question and answer, along with a label indicating which answer the user is on
4. Display the answer
5. If they select yes save the answer in the `multiselect_answer` variable
6. Repeat

```stack
card CheckEndMultiselect
     when questions[question_num].question_type == "multiselect_question" and
            answer_num == count(questions[question_num].answers),
     then: StoreResponse do
  question_num = question_num + 1
  # write the answer results
  question_id = questions[question_num].semantic_id
  log("Answered @multiselect_answer to question @question_num")
end

card CheckEndMultiselect do
  then(DisplayMultiselectAnswer)
end

card DisplayMultiselectAnswer, then: MultiselectError do
  display_answer_num = answer_num + 1
  num_answers = count(question.answers)
  multiselect_question_text = "@question_text"
  answer = question.answers[answer_num]
  answer_text = answer.answer
  # Add in the Answer
  # Add in the placeholder for x / y
  multiselect_question_text =
    concatenate(
      multiselect_question_text,
      "@unichar(10)",
      "@unichar(10)",
      "@answer_text",
      "@unichar(10)",
      "@unichar(10)",
      "@display_answer_num / @num_answers"
    )

  question_response =
    buttons(MultiselectResponseYes: "Yes", MultiselectResponseNo: "No") do
      text("@multiselect_question_text")
    end
end

card MultiselectError when has_all_members(keywords, [@question_response]),
  then: DisplayMultiselectAnswer do
  explainer =
    if(
      is_nil_or_empty(question.explainer),
      "*Explainer:* There's no explainer for this.",
      concatenate("*Explainer:*", " ", question.explainer)
    )

  text("@explainer")
end

card MultiselectError when lower(@question_response) == "skip", then: CheckEndMultiselect do
  # If they skip a question we should 
  # - record the answer as "skip"
  # - increment skip_count
  # - do not count the question towards the score
  # - do not add the max score for this question (i.e. completely exclude this question from scoring)
  question_id = questions[question_num].semantic_id

  skip_count = skip_count + 1

  max_score = max_score - max_question_score

  log("Skipping multiselect question @question_num")
  log("Current score: @score, Current max score: @max_score")

  question_num = question_num + 1
end

card MultiselectError, then: DisplayMultiselectAnswer do
  # If we have an error for this question, then use that, otherwise use the generic one
  error = if(is_nil_or_empty(question.error), assessment_data.generic_error, question.error)
  log("Question number is @question_num")
  log("Answer number is @answer_num")
  log("You entered @question_response")
  text("@error")
end

card MultiselectResponseYes,
  then: CheckEndMultiselect do
  answer = find(question.answers, &(&1.answer == answer_text))
  semantic_id = answer.semantic_id
  score = score + answer.score
  log("Current score: @score, Current max score: @max_score")
  answer_num = answer_num + 1

  multiselect_answer =
    if is_nil_or_empty(multiselect_answer) do
      "@semantic_id"
    else
      concatenate(multiselect_answer, ",", "@semantic_id")
    end
end

card MultiselectResponseNo, then: CheckEndMultiselect do
  answer_num = answer_num + 1
end

```

## Question Response

Here we record the responses to each question.

* For freetext questions we record the full answer.
* For categorical or multiselect questions we record the semantic_id of the answer(s).

We record the following Flow Results:

* `question_num`, the question number
* `answer`, the final answer which will be a comma separated list of all the answers that were selected

```stack
card QuestionResponse when questions[question_num].question_type == "integer_question",
  then: StoreResponse do
  question_id = questions[question_num].semantic_id

  question_num = question_num + 1
end

card QuestionResponse when questions[question_num].question_type == "freetext_question",
  then: StoreResponse do
  question_id = questions[question_num].semantic_id

  question_num = question_num + 1
end

card QuestionResponse when questions[question_num].question_type == "age_question",
  then: StoreResponse do
  question_id = questions[question_num].semantic_id
  log("Answered @age to question @question_num")

  question_num = question_num + 1
end

card QuestionResponse when questions[question_num].question_type == "year_of_birth_question",
  then: StoreResponse do
  question_id = questions[question_num].semantic_id

  question_num = question_num + 1
end

# If Never is a valid response and they respond with Never, skip over everything
card QuestionResponse
     when has_member(map(question.answers, &lower(&1.answer)), "never") and
            lower("@question_response") == "never",
     then: CheckEnd do
  log("Skipping to end of Form")
  answer = find(question.answers, &(&1.answer == question_response))
  question_id = questions[question_num].semantic_id
  log("Answered @answer.answer to question @question_num")

  score = score + answer.score
  question_num = count(questions)
end

card QuestionResponse when lower("@question_response") == "skip", then: StoreResponse do
  # If they skip a question we should 
  # - record the answer as "skip"
  # - increment skip_count
  # - do not count the question towards the score
  # - do not add the max score for this question (i.e. completely exclude this question from scoring)
  question_id = questions[question_num].semantic_id

  skip_count = skip_count + 1

  log("Skipping question @question_num")
  log("Current score: @score, Current max score: @max_score")

  question_num = question_num + 1
end

card QuestionResponse, then: StoreResponse do
  scores = map(question.answers, & &1.score)
  max_question_score = reduce(scores, scores[0], &max(&1, &2))
  answer = find(question.answers, &(&1.answer == question_response))
  question_id = questions[question_num].semantic_id
  log("Answered @answer.answer to question @question_num")

  max_score = max_score + max_question_score
  score = score + answer.score
  log("Current score: @score, Current max score: @max_score")
  question_num = question_num + 1
end

```

## Store Response

These cards are to configure storing the answers of the Form in contact fields. Each question will need its own contact field. Most forms won't need this, so you can comment out or remove the cards (Except the last / default one which is critical to the flow of Forms).

```stack
card StoreResponse when question_id == "dma-do-things" do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  answer = filter(question.answers, &(&1.answer == question_response))
  semantic_id = if(count(answer) == 0, "skip", answer[0].semantic_id)
  write_result("mnch_onboarding_dma_form_dma-do-things", semantic_id)
  update_contact(dma_01: "@question_response")
  then(CheckEnd)
end

card StoreResponse when question_id == "dma-medical-care" do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  answer = filter(question.answers, &(&1.answer == question_response))
  semantic_id = if(count(answer) == 0, "skip", answer[0].semantic_id)
  write_result("mnch_onboarding_dma_form_dma-medical-care", semantic_id)
  update_contact(dma_02: "@question_response")
  then(CheckEnd)
end

card StoreResponse when question_id == "dma-sharing" do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  answer = filter(question.answers, &(&1.answer == question_response))
  semantic_id = if(count(answer) == 0, "skip", answer[0].semantic_id)
  write_result("mnch_onboarding_dma_form_dma-sharing", semantic_id)
  update_contact(dma_03: "@question_response")
  then(CheckEnd)
end

card StoreResponse when question_id == "dma-medical-advice" do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  answer = filter(question.answers, &(&1.answer == question_response))
  semantic_id = if(count(answer) == 0, "skip", answer[0].semantic_id)
  write_result("mnch_onboarding_dma_form_dma-medical-advice", semantic_id)
  update_contact(dma_04: "@question_response")
  then(CheckEnd)
end

card StoreResponse when question_id == "dma-find-solutions" do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  answer = filter(question.answers, &(&1.answer == question_response))
  semantic_id = if(count(answer) == 0, "skip", answer[0].semantic_id)
  write_result("mnch_onboarding_dma_form_dma-find-solutions", semantic_id)
  update_contact(dma_05: "@question_response")
  then(CheckEnd)
end

# This card should be left alone
card StoreResponse do
  then(CheckEnd)
end

```

## End

We record the final result of the Form, and display the correct End page (high, medium, low).

We record the following Flow Results:

* `assessment_risk`, `low`, `medium`, or `high` depending on the risk.

```stack
card End
     when skip_count < skip_threshold and
            score_perc >= assessment_data.high_inflection do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_risk", "high")
  log("Assessment risk: high")
  page_id = assessment_data.high_result_page.id

  then(DisplayEndPage)
end

card End
     when skip_count < skip_threshold and
            score_perc >= assessment_data.medium_inflection and
            score_perc < assessment_data.high_inflection do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_risk", "medium")
  log("Assessment risk: medium")
  page_id = assessment_data.medium_result_page.id

  then(DisplayEndPage)
end

card End when skip_count >= skip_threshold do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_risk", "skip_high")
  log("Assessment risk: skip_high")
  page_id = assessment_data.skip_high_result_page.id

  then(DisplayEndPage)
end

card End do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_risk", "low")
  log("Assessment risk: low")
  page_id = assessment_data.low_result_page.id

  then(DisplayEndPage)
end

card DisplayEndPage do
  # TODO: remove this hard-coding once we can have dynamic labels for flow results
  write_result("mnch_onboarding_dma_form_v1.0_score", score)
  write_result("mnch_onboarding_dma_form_v1.0_max_score", max_score)

  response =
    get("https://content-repo-api-qa.prk-k8s.prd-p6t.org/api/v2/pages/@page_id/",
      timeout: 5_000,
      cache_ttl: 60_000,
      query: [
        ["whatsapp", "true"]
      ],
      headers: [
        ["content-type", "application/json"],
        ["authorization", "Token @global.config.contentrepo_token"]
      ]
    )

  log("@page_id")
  message_body = response.body.body.text.value.message
  text("@message_body")
end

```