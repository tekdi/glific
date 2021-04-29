defmodule GlificWeb.StripeController do
  @moduledoc """
  The controller for all events received from Stripe
  """

  use GlificWeb, :controller

  alias Glific.Partners.{
    Billing,
    Invoice
  }

  alias Glific.Repo
  require Logger

  @doc """
  The top level API used by the router. Use pattern matching to handle specific events
  """
  @spec stripe_webhook(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def stripe_webhook(
        %Plug.Conn{assigns: %{stripe_event: stripe_event, organization_id: organization_id}} =
          conn,
        _params
      ) do
    organization_id = organization_id(stripe_event, organization_id)

    case handle_webhook(stripe_event, organization_id) do
      {:ok, _} -> handle_success(conn)
      {:error, error} -> handle_error(conn, error)
    end
  end

  ## We might need to move this to stripe webhook plug.
  ## I am just not sure that how it will impact on other request and if the
  ## customer id is present in all endpoints.
  @spec organization_id(any(), non_neg_integer) :: non_neg_integer
  defp organization_id(stripe_event, default) do
    object = stripe_event.data.object
    customer_id = get_customer_id(stripe_event.type, object)

    with true <- is_struct(object),
         {:ok, billing} <-
           Repo.fetch_by(Billing, %{stripe_customer_id: customer_id}, skip_organization_id: true) do
      Logger.info("Stripe webhook: #{stripe_event.type}, org: #{billing.organization_id}")

      Repo.put_process_state(billing.organization_id)
      billing.organization_id
    else
      _ -> default
    end
  end

  defp get_customer_id("customer.updated", object), do: object.id

  defp get_customer_id("customer.deleted", object) do
    customer = object |> Map.from_struct()
    customer.id
  end

  defp get_customer_id(_event, object), do: object.customer

  @spec handle_success(Plug.Conn.t()) :: Plug.Conn.t()
  defp handle_success(conn) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "ok")
  end

  @spec handle_error(Plug.Conn.t(), String.t()) :: Plug.Conn.t()
  defp handle_error(conn, error) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(422, error)
  end

  @spec handle_webhook(map(), non_neg_integer) :: {:ok | :error, String.t()}
  defp handle_webhook(
         %{type: "invoice.created", data: %{object: invoice}} = _stripe_event,
         organization_id
       ) do
    case Invoice.create_invoice(%{stripe_invoice: invoice, organization_id: organization_id}) do
      {:ok, invoice} -> {:ok, "success, #{invoice.id}"}
      {:error, error} -> {:error, error}
    end
  end

  defp handle_webhook(
         %{type: "invoice.payment_succeeded", data: %{object: invoice}} = _stripe_event,
         _organization_id
       ),
       do: Invoice.update_invoice_status(invoice.id, "paid")

  defp handle_webhook(
         %{type: "invoice.payment_failed", data: %{object: invoice}} = _stripe_event,
         _organization_id
       ),
       do: Invoice.update_invoice_status(invoice.id, "payment_failed")

  defp handle_webhook(
         %{type: "customer.subscription.updated", data: %{object: subscription}} = _stripe_event,
         organization_id
       ),
       do: Billing.update_subscription_details(subscription, organization_id, nil)

  defp handle_webhook(
         %{type: "customer.updated", data: %{object: customer}} = _stripe_event,
         organization_id
       ) do
    Billing.get_billing(%{stripe_customer_id: customer.id, organization_id: organization_id})
    |> Billing.update_billing(%{email: customer.email})
  end

  defp handle_webhook(
         %{type: "customer.deleted", data: %{object: object}} = _stripe_event,
         organization_id
       ) do
    customer = object |> Map.from_struct()

    Billing.get_billing(%{stripe_customer_id: customer.id, organization_id: organization_id})
    |> Billing.delete_billing()
  end

  defp handle_webhook(stripe_event, _organization_id) do
    # handle default case. We ignore these web hooks.
    {:ok, "success, ignoring #{stripe_event.type}"}
  end
end
