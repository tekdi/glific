defmodule Glific.Flows.Category do
  @moduledoc """
  The Category object which encapsulates one category in a given node.
  """
  alias __MODULE__

  use Ecto.Schema
  import Ecto.Changeset

  alias Glific.Flows.{
    Case,
    Exit,
    FlowContext,
    Router
  }

  @required_fields [:name, :exit_uuid, :router_uuid]
  @optional_fields []

  @type t() :: %__MODULE__{
          uuid: Ecto.UUID.t() | nil,
          name: String.t() | nil,
          cases: [Case.t()] | [],
          exit_uuid: Ecto.UUID.t() | nil,
          exit: Exit.t() | nil,
          router_uuid: Ecto.UUID.t() | nil,
          router: Router.t() | nil
        }

  embedded_schema do
    field :uuid, Ecto.UUID
    field :name, :string

    embeds_many :cases, Case

    field :router_uuid, Ecto.UUID
    embeds_one :router, Router

    field :exit_uuid, Ecto.UUID
    embeds_one :exit, Exit
  end

  @doc """
  Standard changeset pattern we use for all data types
  """
  @spec changeset(Category.t(), map()) :: Ecto.Changeset.t()
  def changeset(category, attrs) do
    category
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> foreign_key_constraint(:router_uuid)
    |> foreign_key_constraint(:exit_uuid)
  end

  @doc """
  Process a json structure from floweditor to the Glific data types
  """
  @spec process(map(), map(), Router.t()) :: {Category.t(), map()}
  def process(json, uuid_map, router) do
    category = %Category{
      uuid: json["uuid"],
      router_uuid: router.uuid,
      exit_uuid: json["exit_uuid"],
      name: json["name"]
    }

    {category, Map.put(uuid_map, category.uuid, {:category, category})}
  end

  @doc """
  Execute a category, given a message stream.
  """
  @spec execute(Category.t(), FlowContext.t(), [String.t()]) ::
          {:ok, FlowContext.t(), [String.t()]} | {:error, String.t()}
  def execute(category, context, message_stream) do
    # transfer control to the exit node
    {:ok, {:exit, exit}} = Map.fetch(context.uuid_map, category.exit_uuid)
    Exit.execute(exit, context, message_stream)
  end
end
