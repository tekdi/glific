defmodule Glific.Clients.Lahi do
  @moduledoc """
  Custom webhook implementation specific to Lahi usecase
  """
  alias Glific.{
    ASR.GoogleASR,
    Contacts.Contact,
    Repo
  }

  import Ecto.Query, warn: false

  @doc """
  Tweak GCS Bucket name based Lahi usecase
  """
  @spec gcs_file_name(map()) :: String.t()
  def gcs_file_name(media) do
    contact = Contact |> where([c], c.id == ^media["contact_id"]) |> Repo.one()

    phone_number = contact.phone
    datetime = Timex.now("Asia/Calcutta")
    strftime_str = Timex.format!(datetime, "%FT%T%:z", :strftime)
    phone_number <> "/" <> strftime_str <> Path.extname(media["remote_name"])
  end

  @doc """
  Create a webhook with different signatures, so we can easily implement
  additional functionality as needed
  """

  @spec webhook(String.t(), map()) :: map()
  def webhook("speech_to_text", fields) do
    contact_id = Glific.parse_maybe_integer!(fields["contact"]["id"])
    contact = get_contact_language(contact_id)

    translated_text =
      Glific.parse_maybe_integer!(fields["organization_id"])
      |> GoogleASR.speech_to_text(fields["results"], contact.language.locale)

    translated_text["words"] |> hd()
  end

  def webhook(_, _fields), do: %{}

  defp get_contact_language(contact_id) do
    case Repo.fetch(Contact, contact_id) do
      {:ok, contact} -> contact |> Repo.preload(:language)
      {:error, error} -> error
    end
  end
end
