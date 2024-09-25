defmodule ProfilePregnancyHealthTest do
  use FlowTester.Case

  alias FlowTester.WebhookHandler, as: WH

  alias Onboarding.QA.Helpers

  import Onboarding.QA.Helpers.Macros

  def setup_fake_cms(auth_token) do
    use FakeCMS
    # Start the handler.
    wh_pid = start_link_supervised!({FakeCMS, %FakeCMS.Config{auth_token: auth_token}})

    # Add some content.

    image = %Image{id: 1, title: "Test image", download_url: "https://example.org/image.jpeg"}

    error_pg = %ContentPage{
      slug: "mnch_onboarding_error_handling_button",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button."
        }
      ]
    }

    error_list = %ContentPage{
      slug: "mnch_onboarding_error_handling_list_message",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send."
        }
      ]
    }

    error_number = %ContentPage{
      slug: "mnch_onboarding_unrecognised_number",
      title: "error",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
        }
      ]
    }

    question_01 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_01",
      title: "Pregnancy_QA_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "I've got a *lot* of information on pregnancy! 💡\r\n\r\nTake 2 minutes to answer a few questions so I can find the right info for you.\r\n\r\nIf there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Why are you interested in pregnancy info?*",
          buttons: [
            %Btn.Next{title: "I'm pregnant"},
            %Btn.Next{title: "Partner is pregnant"},
            %Btn.Next{title: "Just curious"}
          ]
        }
      ]
    }

    question_02 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_02",
      title: "Pregnancy_QA_02",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Which month are you expecting your baby to be born?*"
        }
      ]
    }

    question_02_secondary = %ContentPage{
      slug: "mnch_onboarding_secondary_02",
      title: "Secondary_02",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*"
        }
      ]
    }

    edd_unknown = %ContentPage{
      slug: "mnch_onboarding_edd_unknown_1",
      title: "EDD_unknown_1",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in `Settings`",
          buttons: [
            %Btn.Next{title: "Update due date"},
            %Btn.Next{title: "I’ll do this later"},
          ]
        }
      ]
    }

    edd_unknown_secondary = %ContentPage{
      slug: "mnch_onboarding_edd_unknown_secondary",
      title: "EDD_unknown_secondary",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in `Settings`",
          buttons: [
            %Btn.Next{title: "Update due date"},
            %Btn.Next{title: "I’ll do this later"},
          ]
        }
      ]
    }

    question_03 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_03",
      title: "Pregnancy_QA_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *On what day of the month are you expecting the baby to be born?*\n\nType in a number between 1 and 31. ",
          buttons: []
        }
      ]
    }

    secondary_03 = %ContentPage{
      slug: "mnch_onboarding_secondary_03",
      title: "Secondary_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *On what day of the month are you expecting the baby to be born?*\r\n\r\nType in a number between 1 and 31."
        }
      ]
    }

    secondary_04 = %ContentPage{
      slug: "mnch_onboarding_secondary_04",
      title: "Secondary_04",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *What gender do you identify most with?*",
          buttons: [
            %Btn.Next{title: "Male"},
            %Btn.Next{title: "Female"},
            %Btn.Next{title: "Other"}
          ]
        }
      ]
    }

    curious_01 = %ContentPage{
      slug: "mnch_onboarding_curious_01",
      title: "Pregnancy_QA_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *What gender do you identify most with?*",
          buttons: [
            %Btn.Next{title: "Male"},
            %Btn.Next{title: "Female"},
            %Btn.Next{title: "Other"}
          ]
        }
      ]
    }

    curious_02 = %ContentPage{
      slug: "mnch_onboarding_curious_02",
      title: "Pregnancy_QA_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Tell me, do you have any children?*",
          buttons: []
        }
      ]
    }

    curious_03 = %ContentPage{
      slug: "mnch_onboarding_curious_03",
      title: "Pregnancy_QA_03",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "👤 *Which stage of pregnancy are you most interested in?*	 ",
          buttons: []
        }
      ]
    }

    confirm_edd = %ContentPage{
      slug: "mnch_onboarding_confirm_edd",
      title: "Confirm_EDD",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thank you! Just confirming your estimated due date 🗓️\r\n\r\nAre you expecting the baby on *{dd} {month_name} {yyyy}*?",
          buttons: [
            %Btn.Next{title: "Yes, that's right"},
            %Btn.Next{title: "Pick another date"},
          ]
        }
      ]
    }

    confirm_edd_secondary = %ContentPage{
      slug: "mnch_onboarding_confirm_edd_secondary",
      title: "Confirm_EDD_secondary",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thank you! Just confirming your estimated due date. 🗓️\r\n\r\nAre you expecting the baby on *{dd} {month_name} {yyyy}*?",
          buttons: [
            %Btn.Next{title: "Yes, that's right"},
            %Btn.Next{title: "Pick another date"},
          ]
        }
      ]
    }

    question_05 = %ContentPage{
      slug: "mnch_onboarding_pregnancy_qa_05",
      title: "Pregnancy_QA_05",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thank you! \n\n👤 *How are you feeling about this pregnancy?*",
          list_items: [
            %ListItem{value: "Excited"},
            %ListItem{value: "Happy"},
            %ListItem{value: "Worried"},
            %ListItem{value: "Scared"},
            %ListItem{value: "Other"},
          ]
        }
      ]
    }

    excited_happy_first = %ContentPage{
      slug: "mnch_sentiment_excited_happy_first",
      title: "excited_happy_first",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Congratulations on your pregnancy*🤰🏾\r\n\r\nEven if you can't see your baby bump yet, there's a lot going on!\r\n\r\nYour baby is growing quickly and doing amazing things like developing a brain, heart, facial features, and even tiny feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 There's so much to look forward to!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    excited_happy_second = %ContentPage{
      slug: "mnch_sentiment_excited_happy_second",
      title: "excited_happy_second",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Congratulations! You're in your 2nd trimester*🤰🏾\r\n\r\nInside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    excited_happy_third = %ContentPage{
      slug: "mnch_sentiment_excited_happy_third",
      title: "excited_happy_third",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    scared_worried_first = %ContentPage{
      slug: "mnch_sentiment_scared_worried_first",
      title: "scared_worried_first",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s okay that you’re feeling this way about being pregnant – it’s a big life change*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    scared_worried_second = %ContentPage{
      slug: "mnch_sentiment_scared_worried_second",
      title: "scared_worried_second",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s okay that you’re feeling this way about being pregnant*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    scared_worried_third = %ContentPage{
      slug: "mnch_sentiment_scared_worried_third",
      title: "scared_worried_third",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s normal to feel this way about a pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    other_first = %ContentPage{
      slug: "mnch_sentiment_other_first",
      title: "other_first",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    other_second = %ContentPage{
      slug: "mnch_sentiment_other_second",
      title: "other_second",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    other_third = %ContentPage{
      slug: "mnch_sentiment_other_third",
      title: "other_third",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
          buttons: [
            %Btn.Next{title: "Let's check it out"},
          ],
          image: image.id
        }
      ]
    }

    loading_01 = %ContentPage{
      slug: "mnch_onboarding_loading_01",
      title: "Loading_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thanks {@username} 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
          buttons: [
            %Btn.Next{title: "Okay"},
          ],
          image: image.id
        }
      ]
    }

    loading_01_secondary = %ContentPage{
      slug: "mnch_onboarding_loading_01_secondary",
      title: "Loading_01_secondary",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thanks, {@username}!\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
          buttons: [
            %Btn.Next{title: "Okay"},
          ],
          image: image.id
        }
      ]
    }

    loading_02_secondary = %ContentPage{
      slug: "mnch_onboarding_loading_02_secondary",
      title: "Loading_02_secondary",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "{interesting facts for stage of pregnancy, specifically tailored to partner}",
          buttons: [
            %Btn.Next{title: "Got it"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_1_trimester_1 = %ContentPage{
      slug: "mnch_facts_factoid_1_trimester_1",
      title: "factoid_1_trimester_1",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_2_trimester_1 = %ContentPage{
      slug: "mnch_facts_factoid_2_trimester_1",
      title: "factoid_2_trimester_1",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_1_trimester_2 = %ContentPage{
      slug: "mnch_facts_factoid_1_trimester_2",
      title: "factoid_1_trimester_2",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_2_trimester_2 = %ContentPage{
      slug: "mnch_facts_factoid_2_trimester_2",
      title: "factoid_2_trimester_2",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_1_trimester_3 = %ContentPage{
      slug: "mnch_facts_factoid_1_trimester_3",
      title: "factoid_1_trimester_3",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    facts_factoid_2_trimester_3 = %ContentPage{
      slug: "mnch_facts_factoid_2_trimester_3",
      title: "factoid_2_trimester_3",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰🏽",
          buttons: [
            %Btn.Next{title: "Awesome"},
          ],
          image: image.id
        }
      ]
    }

    topics = %ContentPage{
      slug: "mnch_onboarding_topics_01",
      title: "Topics_01",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list_items: [
            %ListItem{value: "item 1"},
            %ListItem{value: "item 2"},
            %ListItem{value: "item 3"},
            %ListItem{value: "item 4"},
            %ListItem{value: "Show me other topics"},
          ],
          image: image.id
        }
      ]
    }

    content_intro = %ContentPage{
      slug: "mnch_onboarding_content_intro",
      title: "Content_intro",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
          list_items: [
            %ListItem{value: "Managing mood swings"},
            %ListItem{value: "This week"},
            %ListItem{value: "The third trimester"},
            %ListItem{value: "Clinic visits"},
            %ListItem{value: "Show me other topics"},
          ],
          image: image.id
        }
      ]
    }

    article_topic_01_secondary = %ContentPage{
      slug: "mnch_onboarding_article_topic_01_secondary",
      title: "Article_topic_01_secondary",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "Rate this article"},
            %Btn.Next{title: "Choose another topic"}
          ],
          image: image.id
        }
      ]
    }

    article_feedback = %ContentPage{
      slug: "mnch_onboarding_content_feedback",
      title: "Content_feedback",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Was this the information you were looking for?",
          buttons: [
            %Btn.Next{title: "Yes"},
            %Btn.Next{title: "Not really"},
          ],
          image: image.id
        }
      ]
    }

    article_feedback_no = %ContentPage{
      slug: "mnch_onboarding_content_feedback_no",
      title: "Content_feedback_no",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Mmm, maybe I need a bit more information about you... 🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
          buttons: [
            %Btn.Next{title: "Yes, sure ✅"},
            %Btn.Next{title: "Maybe later"},
            %Btn.Next{title: "No thanks"},
          ],
          image: image.id
        }
      ]
    }

    opt_in = %ContentPage{
      slug: "mnch_onboarding_reminder_opt_in",
      title: "Reminder_opt_in",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "*Be a big support to your partner!* 🔔\r\n\r\nCan we send you notifications with weekly information that will help you manage your family’s health?",
        }
      ]
    }

    opt_in_yes = %ContentPage{
      slug: "mnch_onboarding_reminder_opt_in_yes",
      title: "Reminder_opt_in_yes",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Great decision, {username}!\r\n\r\nThese messages are a great way to stay up to date and informed about your baby on the way 💛"
        }
      ]
    }

    opt_in_no = %ContentPage{
      slug: "mnch_onboarding_reminder_opt_in_no",
      title: "Reminder_opt_in_no",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "Thousands of people have signed up to receive these messages – they're the best way to stay in control 🙌🏾\r\n\r\nYou can always change your update choice in `Settings`"
        }
      ]
    }

    progress_25 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_25",
      title: "Profile_progress_25",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Explore health guide"}

          ]
        }
      ]
    }

    progress_25_secondary = %ContentPage{
      slug: "mnch_onboarding_profile_progress_25_secondary",
      title: "Profile_progress_25",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Explore health guide"}

          ]
        }
      ]
    }

    progress_25_secondary_2 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_25_secondary_",
      title: "Profile_progress_25",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "➡️ Complete profile"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Explore health guide"}

          ]
        }
      ]
    }

    progress_50 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_50",
      title: "Profile_progress_50",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete! 🎉\r\n\r\n🤰🏽 Pregnancy info {pregnancy_info_count}\r\n👤 Basic information {basic_info_count}\r\n➡️ Personal information {personal_info_count}\r\n⬜ Daily life {daily_life_count}\r\n\r\n👇🏾 Let’s move on to personal information.",
          buttons: [
            %Btn.Next{title: "Continue"}

          ]
        }
      ]
    }

    progress_100 = %ContentPage{
      slug: "mnch_onboarding_profile_progress_100",
      title: "Profile_progress_100",
      parent: "test",
      wa_messages: [
        %WAMsg{
          message: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete! 🎉 🌟\r\n\r\nYou can always edit it or provide more info.\r\n*Profile name:* {name}\r\n*Baby due date:* {edd}\r\n*Profile questions:* {profile_questions}\r\n*Get important messages:* {get_important_messages}\r\n\r\n👇🏽 What do you want to do next?",
          buttons: [
            %Btn.Next{title: "Explore health guide"},
            %Btn.Next{title: "View topics for you"},
            %Btn.Next{title: "Go to main menu"}
          ]
        }
      ]
    }

    assert :ok =
             FakeCMS.add_pages(wh_pid, [
               %Index{slug: "test", title: "test"},
               error_pg,
               error_list,
               error_number,
               question_01,
               question_02,
               question_02_secondary,
               question_03,
               secondary_03,
               secondary_04,
               edd_unknown,
               edd_unknown_secondary,
               confirm_edd,
               confirm_edd_secondary,
               question_05,
               curious_01,
               curious_02,
               curious_03,
               excited_happy_first,
               excited_happy_second,
               excited_happy_third,
               scared_worried_first,
               scared_worried_second,
               scared_worried_third,
               other_first,
               other_second,
               other_third,
               loading_01,
               loading_01_secondary,
               loading_02_secondary,
               facts_factoid_1_trimester_1,
               facts_factoid_2_trimester_1,
               facts_factoid_1_trimester_2,
               facts_factoid_2_trimester_2,
               facts_factoid_1_trimester_3,
               facts_factoid_2_trimester_3,
               topics,
               content_intro,
               article_topic_01_secondary,
               article_feedback,
               article_feedback_no,
               opt_in,
               opt_in_yes,
               opt_in_no,
               progress_25,
               progress_25_secondary,
               progress_25_secondary_2,
               progress_50,
               progress_100,
             ])

    assert :ok = FakeCMS.add_images(wh_pid, [image])

    # Return the adapter.
    FakeCMS.wh_adapter(wh_pid)
  end

  defp real_or_fake_cms(step, base_url, _auth_token, :real),
    do: WH.allow_http(step, base_url)

  defp real_or_fake_cms(step, base_url, auth_token, :fake),
    do: WH.set_adapter(step, base_url, setup_fake_cms(auth_token))

  defp setup_flow() do
    # When talking to real contentrepo, get the auth token from the API_TOKEN envvar.
    auth_token = System.get_env("API_TOKEN", "CRauthTOKEN123")
    kind = if auth_token == "CRauthTOKEN123", do: :fake, else: :real

    Helpers.flow_path("profile-pregnancy-health")
    |> FlowTester.from_json!()
    |> real_or_fake_cms("https://content-repo-api-qa.prk-k8s.prd-p6t.org/", auth_token, kind)
    |> FlowTester.set_global_dict("config", %{"contentrepo_token" => auth_token})
  end

  defp init_pregnancy_info(context) do
    context |> FlowTester.set_contact_properties(%{"pregnancy_status" => "im_pregnant", "edd" => "24/04/2026", "pregnancy_sentiment" => "excited"})
  end

  defp init_contact_fields(context) do
    context |> FlowTester.set_contact_properties(%{"gender" => "", "name" => "Lily", "opted_in" => "true"})
  end

  defp get_months() do
    this_month = DateTime.utc_now()
    [
      this_month,
      Date.shift(this_month, month: 1),
      Date.shift(this_month, month: 2),
      Date.shift(this_month, month: 3),
      Date.shift(this_month, month: 4),
      Date.shift(this_month, month: 5),
      Date.shift(this_month, month: 6),
      Date.shift(this_month, month: 7),
      Date.shift(this_month, month: 8)
    ]

  end

  defp get_month_words(months) do
    [
      Calendar.strftime(Enum.at(months, 0), "%B"),
      Calendar.strftime(Enum.at(months, 1), "%B"),
      Calendar.strftime(Enum.at(months, 2), "%B"),
      Calendar.strftime(Enum.at(months, 3), "%B"),
      Calendar.strftime(Enum.at(months, 4), "%B"),
      Calendar.strftime(Enum.at(months, 5), "%B"),
      Calendar.strftime(Enum.at(months, 6), "%B"),
      Calendar.strftime(Enum.at(months, 7), "%B"),
      Calendar.strftime(Enum.at(months, 8), "%B")
    ]
  end

  defp get_edd(months, month_words, selected_edd_day \\ 25, selected_edd_month \\ 1) do
    list_of_months = [
      {"@datevalue(this_month, \"%B\")", "#{Enum.at(month_words, 0)}"},
      {"@datevalue(this_month_plus_one, \"%B\")", "#{Enum.at(month_words, 1)}"},
      {"@datevalue(this_month_plus_two, \"%B\")", "#{Enum.at(month_words, 2)}"},
      {"@datevalue(this_month_plus_three, \"%B\")", "#{Enum.at(month_words, 3)}"},
      {"@datevalue(this_month_plus_four, \"%B\")", "#{Enum.at(month_words, 4)}"},
      {"@datevalue(this_month_plus_five, \"%B\")", "#{Enum.at(month_words, 5)}"},
      {"@datevalue(this_month_plus_six, \"%B\")", "#{Enum.at(month_words, 6)}"},
      {"@datevalue(this_month_plus_seven, \"%B\")", "#{Enum.at(month_words, 7)}"},
      {"@datevalue(this_month_plus_eight, \"%B\")", "#{Enum.at(month_words, 8)}"},
      {"I don't know", "I don't know"}
    ]

    edd_confirmation_text = "Thank you! Just confirming your estimated due date 🗓️\r\n\r\nAre you expecting the baby on *#{selected_edd_day} #{Enum.at(month_words, selected_edd_month)} #{Calendar.strftime(Enum.at(months, selected_edd_month), "%Y")}*?"

    edd_month = String.pad_leading("#{Enum.at(months, selected_edd_month).month}", 2, "0")
    full_edd = Calendar.strftime(Enum.at(months, 1), "%Y") <> "-" <> "#{edd_month}" <> "-#{selected_edd_day}"

    {list_of_months, edd_confirmation_text, full_edd}
  end

  describe "checkpoints" do
    test "pregnant mom 0%" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "pregnant mom 25%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "pregnant mom 50%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "pregnant mom 100%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnant_mom_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "partner pregnant 0%" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "partner pregnant 25%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "partner pregnant 50%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "partner pregnant 100%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "curious 0%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "0%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "curious 25%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "25%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "curious 50%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "50%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "curious 100%" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "curious_pregnancy_profile", "profile_completion" => "100%"})
      |> FlowTester.start()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "pregnancy_basic_info" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_basic_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_basic_profile_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "pregnancy_personal_info" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_personal_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_personal_info_flow(relationship_status: "single", education: "degree", socio_economic: "i get by", other_children: "0")
      |> Helpers.handle_daily_life_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "pregnancy_daily_life_info" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "pregnancy_daily_life_info", "profile_completion" => ""})
      |> FlowTester.start()
      |> Helpers.handle_daily_life_flow()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end

    test "default" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> FlowTester.set_contact_properties(%{"checkpoint" => "", "profile_completion" => ""})
      |> FlowTester.start()
      |> receive_message(%{
        text: "I've got a *lot* of information on pregnancy" <> _,
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
      |> contact_matches(%{"checkpoint" => "basic_pregnancy_profile"})
    end
  end

  describe "profile pregnancy health - pregnant" do
    test "question 1 error" do
      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{
        text: "I've got a *lot* of information on pregnancy! 💡\r\n\r\nTake 2 minutes to answer a few questions so I can find the right info for you.\r\n\r\nIf there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Why are you interested in pregnancy info?*",
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["I'm pregnant", "Partner is pregnant", "Just curious"])
      })
    end

    test "question 1 - i'm pregnant" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then edd day" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 2), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "👤 *On what day of the month are you expecting the baby to be born?*\n\nType in a number between 1 and 31. "
      })
    end

    test "edd month to edd month unknown" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in `Settings`",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown update" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Update due date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month edd month unknown later" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      # TODO: Add this test when we have a way to test for scheduling stacks
      #|> Helpers.handle_edd_reminder_flow()
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "edd day then confirm" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd day then not number error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then not a day error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("0")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then above max day error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then above max day error february 29" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 0), 0)

      setup_flow()
      |> FlowTester.set_fake_time(~U[2024-02-29 00:00:00Z])
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("30")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    # TODO: Tests for Feb, long months, and short months. This requires us to be able to mock the return value of now() so that we can dictacte what options
    # are available in the list of months.

    test "edd confirm then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd confirm then pick another date" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Pick another date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd confirm then that's right" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{
        text: "Thank you! \n\n👤 *How are you feeling about this pregnancy?*",
        list: {"I'm feeling", [{"Excited", "Excited"}, {"Happy", "Happy"}, {"Worried", "Worried"}, {"Scared", "Scared"}, {"Other", "Other"}]}
      })
    end

    test "feelings then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"I'm feeling", [{"Excited", "Excited"}, {"Happy", "Happy"}, {"Worried", "Worried"}, {"Scared", "Scared"}, {"Other", "Other"}]}
      })
    end

    test "feelings then scared 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant – it’s a big life change*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 1st trimester (text only)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant – it’s a big life change*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then scared 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 2nd trimester (text only)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s okay that you’re feeling this way about being pregnant*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then scared 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s normal to feel this way about a pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then scared 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Worried")
      |> contact_matches(%{"pregnancy_sentiment" => "Worried"})
      |> receive_message(%{
        text: "*It’s normal to feel this way about a pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations on your pregnancy*🤰🏾\r\n\r\nEven if you can't see your baby bump yet, there's a lot going on!\r\n\r\nYour baby is growing quickly and doing amazing things like developing a brain, heart, facial features, and even tiny feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 There's so much to look forward to!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 1st trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations on your pregnancy*🤰🏾\r\n\r\nEven if you can't see your baby bump yet, there's a lot going on!\r\n\r\nYour baby is growing quickly and doing amazing things like developing a brain, heart, facial features, and even tiny feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 There's so much to look forward to!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 2nd trimester*🤰🏾\r\n\r\nInside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 2nd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 2nd trimester*🤰🏾\r\n\r\nInside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then excited 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!" <> _,
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then excited 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{
        text: "*Congratulations! You're in your 3rd trimester*🤰🏾\r\n\r\nYour belly is probably bigger than you thought it could get! Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!" <> _,
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 1st trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nJust remember that you are strong and capable. The more information you have, the more you can prepare for what's coming next 🌟\r\n\r\nYour baby is growing quickly, already developing a brain, heart, facial features, and even feet, hands, fingernails, and toenails.\r\n\r\n👇🏽 Let's have a look at what you can expect.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 2nd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nTake a moment to think about what an amazing thing you're doing. Inside your belly, your baby's organs and systems are all formed. Now it's time for them to grow! By the end of this trimester, your baby will be about the size of a cauliflower.\r\n\r\nHopefully you're not still experiencing vomitting and nausea. There are some other symptoms you can expect during the 2nd trimester.\r\n\r\n👇🏽 Be prepared by learning what they are.",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "feelings then other 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "feelings then other 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{
        text: "*It’s normal to have mixed feelings about your pregnancy*\r\n\r\nIt's important to remember that you are strong and capable.\r\n\r\nThere is a lot going on during the 3rd trimester. Your belly is probably bigger than you thought it could get. Your baby is gaining weight quickly now, and by 40 weeks, will be the size of a pumpkin!\r\n\r\nThis last stretch can be uncomfortable, but you're nearly there 🌟\r\n\r\n👇🏽 Don’t worry, there are positive things coming!",
        buttons: button_labels(["Let's check it out"]),
        image: nil
      })
    end

    test "excited 1st trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "excited 2nd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "exited 3rd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 1st trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 2nd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "scared 3rd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 1st trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 2nd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "other 3rd trimester then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Let's check it out"])
      })
    end

    test "excited 1st trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 1st trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "excited 2nd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 2nd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "excited 3rd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "excited 3rd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 1st trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 1st trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> contact_matches(%{"pregnancy_sentiment" => "Scared"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 2nd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 2nd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "scared 3rd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "scared 3rd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Scared")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 1st trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 1st trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> contact_matches(%{"pregnancy_sentiment" => "Other"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 2nd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 2nd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "other 3rd trimester then loading 1 (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "other 3rd trimester then loading 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{
        text: "Thanks Lily 🌟\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"]),
        image: nil
      })
    end

    test "loading 1 then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then factoid 1 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 1st trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA uterus can stretch from the size of a lemon to the size of a watermelon during pregnancy 🍋",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "loading 1 then factoid 1 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 2nd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nMoms-to-be can start producing breast milk as early as 14 weeks into their pregnancy! 🍼",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "loading 1 then factoid 1 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "loading 1 then factoid 1 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!" <> _,
        buttons: button_labels(["Awesome"])
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then factoid 2 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 1st trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nA woman's blood volume can increase by 40 to 50 percent during pregnancy. This provides the extra oxygen needed for a healthy pregnancy 🤰🏽",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then factoid 2 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 2nd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nBabies can start to taste flavours even before they're born. From week 14 or 15, from the food you eat enters your bloodstream and the fluid surrounding the baby in the womb.",
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 1 then factoid 2 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰" <> _,
        buttons: button_labels(["Awesome"]),
        image: "https://example.org/image.jpeg"
      })
    end

    test "factoid 1 then factoid 2 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "*Did you know* 💡\r\n\r\nBy the third trimester, a developing baby can recognise their mother’s voice from inside the womb 🤰" <> _,
        buttons: button_labels(["Awesome"]),
        image: nil
      })
    end

    test "factoid 2 then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 2 then topics 1st trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 1st trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "factoid 2 then topics 2nd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 2nd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 4)
      month = elem(Enum.at(list_of_months, 4), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "factoid 2 then topics 3rd trimester (all)" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 1)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "all"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
      }])
    end

    test "factoid 2 then topics 3rd trimester" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 1)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "topics then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "topics then dummy topic" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{
        text: "TODO: Get the article content and display it here" <> _,
        buttons: [{"Complete Profile", "Complete Profile"}, {"Rate this article", "Rate this article"}, {"Choose another topic", "Choose another topic"}]
      })
    end

    test "dummy topic then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: [{"Complete Profile", "Complete Profile"}, {"Rate this article", "Rate this article"}, {"Choose another topic", "Choose another topic"}]
      })
    end

    test "dummy topic then choose another topic" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Choose another topic")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
        list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]},
        image: nil
      })
    end

    test "dummy topic then rate this article" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then yes" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "rate this article then not really" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{
        text: "Mmm, maybe I need a bit more information about you... 🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure ✅", "Maybe later", "No thanks"])
      })
    end

    test "Not really then yes sure" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, sure ✅")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
      |> contact_matches(%{"profile_completion" => "50%"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "not really then maybe later" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Maybe later")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "not really then no thanks" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "No thanks")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "dummy topic then complete profile" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Complete Profile")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "25% then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Complete Profile")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜ \r\n\r\nYour profile is already 25% complete! I think now is a good time to complete it, but it's up to you.\r\n\r\n👇🏽 What do you want to do next?" <> _,
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "25% complete then view topics" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "View topics for you")
      |> receive_message(%{
        text: "TODO",
      })
      |> flow_finished()
    end

    test "25% complete then explore health guide" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Explore health guide")
      |> receive_message(%{
        text: "TODO",
      })
      |> flow_finished()
    end

    test "25% complete then complete profile" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
      |> contact_matches(%{"profile_completion" => "50%"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "Pregnancy info 3/3")
        assert String.contains?(msg.text, "Basic information 3/4")
        assert String.contains?(msg.text, "Personal information 0/4")
        assert String.contains?(msg.text, "Daily life 0/5")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩⬜⬜⬜⬜ \r\n\r\nYour profile is already 50% complete" <> _,
        buttons: button_labels(["Continue"])
      })
    end

    test "50% complete then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words, 25, 8)
      month = elem(Enum.at(list_of_months, 8), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.set_contact_properties(%{"opted_in" => "false"})
      |> FlowTester.set_contact_properties(%{"data_preference" => "text only"})
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send("Other")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes")
      |> Helpers.handle_opt_in_reminder_flow()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Continue"])
      })
    end

    test "100% complete" do
      months = get_months()
      month_words = get_month_words(months)
      {_list_of_months, _edd_confirmation_text, full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I'm pregnant")
      |> contact_matches(%{"gender" => "female", "pregnancy_status" => "im_pregnant", "checkpoint" => "pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: Enum.at(month_words, 1))
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> contact_matches(%{"edd" => ^full_edd})
      |> receive_message(%{})
      |> FlowTester.send("Excited")
      |> contact_matches(%{"pregnancy_sentiment" => "Excited"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Let's check it out")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_messages([
        %{image: "https://example.org/image.jpeg"},
        %{
          text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your pregnancy this week* 🗓️\r\nYou’re in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip your clinic visits!* 🏥\r\nWhy you should see a health worker throughout your pregnancy.\r\n\r\nChoose a topic to read more about it.",
          list: {"Choose a Topic", [{"item 1", "item 1"}, {"item 2", "item 2"}, {"item 3", "item 3"}, {"item 4", "item 4"}, {"Show me other topics", "Show me other topics"}]}
      }])
      |> FlowTester.send("item 1")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Complete Profile")
      |> contact_matches(%{"profile_completion" => "25%"})
      |> receive_message(%{})
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> Helpers.handle_basic_profile_flow(year_of_birth: "1988", province: "Western Cape", area_type: "", gender: "male")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Continue")
      |> Helpers.handle_personal_info_flow(relationship_status: "", education: "", socio_economic: "", other_children: "")
      |> Helpers.handle_daily_life_flow()
      |> contact_matches(%{"profile_completion" => "100%"})
      |> fn step ->
        [msg] = step.messages
        assert String.contains?(msg.text, "*Profile name:* Lily")
        assert String.contains?(msg.text, "*Baby due date:* #{full_edd}")
        assert String.contains?(msg.text, "*Profile questions:* 6/11")
        assert String.contains?(msg.text, "*Get important messages:* ✅")
        step
      end.()
      |> receive_message(%{
        text: "🟩🟩🟩🟩🟩🟩🟩🟩\r\n\r\nYour profile is 100% complete" <> _,
        buttons: button_labels(["Explore health guide", "View topics for you", "Go to main menu"])
      })
    end
  end

  describe "profile pregnancy health - partner pregnant" do
    test "question 1 - partner is pregnant" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> contact_matches(%{"gender" => "", "pregnancy_status" => "partner_pregnant", "checkpoint" => "partner_of_pregnant_mom_profile", "profile_completion" => "0%"})
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month then edd day" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 2), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{
        text: "👤 *On what day of the month are you expecting the baby to be born?*\n\nType in a number between 1 and 31. "
      })
    end

    test "edd month to edd month unknown" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{
        text: "*It's important to know the due date* 🗓️\r\n\r\nThere are two ways to calculate it:\r\n\r\n• Count 40 weeks (or 280 days) forward from the first day of your last menstrual period.\r\n\r\n• Use this free due date calculator: https://www.pampers.com/en-us/pregnancy/due-date-calculator\r\n\r\nAsk a health worker to confirm your expected due date at your next clinic vist 🧑🏾‍⚕️\r\n\r\nYou can update your expected due date at any time in `Settings`",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Update due date", "I’ll do this later"])
      })
    end

    test "edd month unknown update" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Update due date")
      |> receive_message(%{
        text: "If there are any questions you don’t want to answer right now, reply `Skip`\r\n\r\n👤 *Which month are you expecting your baby to be born?*",
        list: {"Month", ^list_of_months}
      })
    end

    test "edd month edd month unknown later" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      # TODO: Add this test when we have a way to test for scheduling stacks
      #|> Helpers.handle_edd_reminder_flow()
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "edd day then confirm" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{
        text: ^edd_confirmation_text,
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd day then not number error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then not a day error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("0")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    test "edd day then above max day error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("32")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽  Please try that again and respond with the number that comes before your answer."
      })
    end

    # TODO: Tests for Feb, long months, and short months. This requires us to be able to mock the return value of now() so that we can dictacte what options
    # are available in the list of months.

    test "edd confirm then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, that's right", "Pick another date"])
      })
    end

    test "edd confirm then pick another date" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Pick another date")
      |> receive_message(%{
        text: "👤 *Which month are you expecting your baby to be born?*" <> _,
        list: {"Month", ^list_of_months}
      })
    end

    test "edd confirm then that's right" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "gender then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{
        text: "👤 *What gender do you identify most with?*",
        buttons: button_labels(["Male", "Female", "Other"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Male", "Female", "Other"])
      })
    end

    test "gender then male" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Male")
      |> contact_matches(%{"gender" => "male"})
      |> receive_message(%{
        text: "Thanks, Lily!\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"])
      })
    end

    test "gender then female" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> contact_matches(%{"gender" => "female"})
      |> receive_message(%{
        text: "Thanks, Lily!\r\n\r\nGive me a moment while I set up your profile and find the best information for you... ⏳",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Okay"])
      })
    end

    test "loading 1 then loading 2 no edd" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "{interesting facts for stage of pregnancy, specifically tailored to partner}",
        buttons: button_labels(["Got it"])
      })
    end

    test "loading 2 then error no edd" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Got it"])
      })
    end

    test "loading 2 then content intro no edd" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)

      last_month = length(list_of_months) - 1

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(elem(Enum.at(list_of_months, last_month), 0))
      |> receive_message(%{})
      |> FlowTester.send(button_label: "I’ll do this later")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Got it")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "loading 1 then factoid 1" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{
        text: "*Did you know?* 💡\r\n\r\nSome women may experience changes in their voice during pregnancy. This is because hormonal changes can cause the vocal cords to swell!",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Awesome"])
      })
    end

    test "factoid 1 then factoid 2 then content intro" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "content intro then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply. Please try that again.\r\n\r\n👇🏽 Tap on the button below the message, choose your answer from the list, and send.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "content intro then article topic" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
    end

    test "article topic then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
    end

    test "article topic then complete" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
      |> FlowTester.send(button_label: "➡️ Complete profile")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end

    test "article topic then choose another topic" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Choose another topic")
      |> receive_message(%{
        text: "Here are some topics picked just for you 💡\r\n\r\n*Managing mood swings* 🎢\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n*Your partner this week* 🗓️\r\nYour partner is in the home stretch. Here are some things you can expect.\r\n\r\n*What is the third trimester?* ⏳\r\nLearn more about the last phase of pregnancy\r\n\r\n*Don’t skip clinic visits!* 🏥\r\nWhy your partner should see a health worker throughout pregnancy.\r\n\r\n👇🏽 Choose a topic to read more about it.",
        list: {"Select option", list_items(["Managing mood swings", "This week", "The third trimester", "Clinic visits", "Show me other topics"], "menu_items")}
      })
    end

    test "article topic then rate this article" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{
        text: "*Managing mood swings* 🎢\r\n[THIS IS JUST FILLER COPY. CONTENT TO BE SOURCED FROM CONTENTREPO.]\r\nHow to manage the ups and downs of pregnancy mood swings\r\n\r\n1. *Avoid Caffeine*: Avoiding caffeine can help stabilise your partner's mood.\r\n2. *Learn Cognitive Behavioral Techniques*: They can help your partner to challenge negative thought patterns that cause mood swings.\r\n3. *Stay Mindful*: Practice mindfulness to stay present and focused.\r\n4. *Consider Professional Help*: If your partner's mood swings are severe or interfering with her daily life, consider seeking help.\r\n5. *Stay Patient and Kind*: Managing mood swings can take time and effort.",
        buttons: button_labels(["➡️ Complete profile", "Rate this article", "Choose another topic"])
      })
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes", "Not really"])
      })
    end

    test "rate this article then no" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{
        text: "Mmm, maybe I need a bit more information about you... 🤔\r\n\r\n👇🏽 Would you like to answer some more questions now?",
        buttons: button_labels(["Yes, sure ✅", "Maybe later", "No thanks"])
      })
    end

    test "content feedback no then error" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Not really")
      |> receive_message(%{})
      |> FlowTester.send("falalalalaaa")
      |> receive_message(%{
        text: "I don't understand your reply.\r\n\r\n👇🏽 Please try that again and respond by tapping a button.",
        buttons: button_labels(["Yes, sure ✅", "Maybe later", "No thanks"])
      })
    end

    test "rate this article then yes opted in" do
      months = get_months()
      month_words = get_month_words(months)
      {list_of_months, _edd_confirmation_text, _full_edd} = get_edd(months, month_words)
      month = elem(Enum.at(list_of_months, 1), 0)

      setup_flow()
      |> Helpers.init_contact_fields()
      |> init_contact_fields()
      |> init_pregnancy_info()
      |> FlowTester.start()
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Partner is pregnant")
      |> receive_message(%{})
      |> FlowTester.send(month)
      |> receive_message(%{})
      |> FlowTester.send("25")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Yes, that's right")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Female")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Okay")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Awesome")
      |> receive_message(%{})
      |> FlowTester.send("@menu_items[0]")
      |> receive_message(%{})
      |> FlowTester.send(button_label: "Rate this article")
      |> receive_message(%{
        text: "Was this the information you were looking for?",
        buttons: button_labels(["Yes", "Not really"])
      })
      |> FlowTester.send(button_label: "Yes")
      |> receive_message(%{
        text: "🟩🟩⬜⬜⬜⬜⬜⬜\r\n\r\nYour profile is already 25% complete!\r\n\r\n👇🏽 What do you want to do next?",
        buttons: button_labels(["➡️ Complete profile", "View topics for you", "Explore health guide"])
      })
    end
  end
end
