defmodule HelpCentre.QA.Helpers do
  alias FlowTester.WebhookHandler.Generic
  alias FlowTester.WebhookHandler, as: WH

  defp turn_contacts_messages(env, ctx) do
    assigned_to =
      Map.get(ctx, :chat_assigned_to, %{
        "id" => "some-uuid",
        "name" => "Test Operator",
        "type" => "OPERATOR"
      })

    body = %{
      "messages" => [
        %{
          "id" => "someid"
        }
      ],
      "chat" => %{
        "owner" => "+27821234567",
        "state" => "OPEN",
        "uuid" => "some-uuid",
        "state_reason" => "Re-opened by inbound message.",
        "assigned_to" => assigned_to,
        "contact_uuid" => "some-uuid",
        "permalink" => "https://whatsapp-praekelt-cloud.turn.io/app/c/some-uuid"
      }
    }

    %Tesla.Env{env | status: 200, body: body}
  end

  defp turn_add_label(env, _ctx) do
    %Tesla.Env{env | status: 200}
  end

  def setup_fake_turn(step, ctx) do
    gen_pid = ExUnit.Callbacks.start_link_supervised!(Generic, id: :fake_turn)

    Generic.add_handler(
      gen_pid,
      ~r"/v1/contacts/[0-9]+/messages",
      &turn_contacts_messages(&1, ctx)
    )

    Generic.add_handler(
      gen_pid,
      "/v1/messages/someid/labels",
      &turn_add_label(&1, ctx)
    )

    WH.set_adapter(step, "https://whatsapp-praekelt-cloud.turn.io/", Generic.wh_adapter(gen_pid))
  end
end
