defmodule GlificWeb.Resolvers.Filesearch do
  @moduledoc """
  Filesearch Resolver which sits between the GraphQL schema and Glific Filesearch API.
  """
  alias Glific.OpenAI.Filesearch
  alias Glific.Filesearch.{Assistant, VectorStore}
  alias Glific.Repo

  @doc """
  Create a Vector Store
  """
  @spec create_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_vector_store(_, %{name: vector_store_name}, %{context: %{current_user: user}}) do
    {:ok, %{vector_store_id: store_id}} = Filesearch.create_vector_store(vector_store_name)

    VectorStore.create_vector_store(%{
      vector_store_id: store_id,
      organization_id: user.organization_id,
      vector_store_name: vector_store_name,
      files: %{}
    })

    {:ok, %{vector_store_id: store_id}}
  end

  @doc """
  Modify a Vector Store
  """
  @spec modify_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def modify_vector_store(_, params, _) do
    Filesearch.modify_vector_store(params)
  end

  @doc """
  Delete a Vector Store
  """
  @spec delete_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, map()} | {:error, any()}
  def delete_vector_store(_, %{vector_store_id: vector_store_id}, _) do
    with {:ok, %{vector_store_id: vector_store_id}} <-
           Filesearch.delete_vector_store(vector_store_id),
         {:ok, openai_vector_store} <-
           Repo.fetch_by(VectorStore, %{vector_store_id: vector_store_id}) do
      VectorStore.delete_vector_store(openai_vector_store)
    end

    {:ok, %{vector_store_id: vector_store_id}}
  end

  @doc """
  Create an assistant
  """
  @spec create_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, map()} | {:error, any()}
  def create_assistant(_, %{input: params}, %{context: %{current_user: user}}) do
    {:ok, %{id: assistant_id}} = Filesearch.create_assistant(params) |> IO.inspect()

    {:ok, assistant} =
      Assistant.create_assistant(%{
        assistant_id: assistant_id,
        name: params.name,
        model: params.model,
        vector_store_id: params[:vector_store_id],
        instructions: params[:instructions],
        settings: params[:settings] || %{temperature: 1.25, max_chunk: 20},
        organization_id: user.organization_id
      })

    {:ok, %{assistant: assistant}}
  end

  @doc """
  Modify vector store
  """
  @spec modify_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def modify_assistant(_, params, _) do
    Filesearch.modify_assistant(params)
  end

  @doc """
  Delete Assistant
  """
  @spec delete_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, map()} | {:error, any()}
  def delete_assistant(_, %{assistant_id: assistant_id} = _args, _) do
    with {:ok, %{assistant_id: assistant_id}} <- Filesearch.delete_assistant(assistant_id),
         {:ok, openai_assistant} <- Repo.fetch_by(Assistant, %{assistant_id: assistant_id}) do
      Assistant.delete_assistant(openai_assistant)
    end

    {:ok, %{assistant_id: assistant_id}}
  end
end
