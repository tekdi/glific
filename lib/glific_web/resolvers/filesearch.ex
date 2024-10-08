defmodule GlificWeb.Resolvers.Filesearch do
  @moduledoc """
  Filesearch Resolver which sits between the GraphQL schema and Glific Filesearch API.
  """
  alias Glific.{
    Filesearch,
    Filesearch.VectorStore,
    Repo
  }

  @doc """
  Create a VectorStore
  """
  @spec create_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_vector_store(_, %{input: params}, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    attrs = %{
      name: params[:name],
      organization_id: user.organization_id,
      files: %{}
    }

    Filesearch.create_vector_store(attrs)
  end

  @doc """
  Uploads a file to openAI

  Returns the File details
  """
  @spec upload_file(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def upload_file(_, params, %{context: %{current_user: _user}}) do
    Filesearch.upload_file(params)
  end

  @doc """
  Deletes the VectorStore for the given ID
  """
  @spec delete_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def delete_vector_store(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    with {:ok, vector_store} <- Filesearch.delete_vector_store(params.id) do
      {:ok, %{vector_store: vector_store}}
    end
  end

  @doc """
  Removes the given file from the VectorStore
  """
  @spec remove_vector_store_file(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def remove_vector_store_file(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    with {:ok, vector_store} <- Filesearch.remove_vector_store_file(params) do
      {:ok, %{vector_store: vector_store}}
    end
  end

  @doc """
  Fetch the details for the given VectorStore
  """
  @spec get_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def get_vector_store(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    with {:ok, vector_store} <- VectorStore.get_vector_store(params.id) do
      {:ok, %{vector_store: vector_store}}
    end
  end

  @doc """
  Fetch VectorStores with given filters and options
  """
  @spec list_vector_stores(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def list_vector_stores(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    {:ok, Filesearch.list_vector_stores(params)}
  end

  @doc """
  Updates the VectorStore with given attrs
  """
  @spec update_vector_store(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def update_vector_store(_, %{id: id, input: attrs}, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    with {:ok, vector_store} <- Filesearch.update_vector_store(id, attrs) do
      {:ok, %{vector_store: vector_store}}
    end
  end

  @doc """
  Create an Assistant
  """
  @spec create_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_assistant(_, %{input: params}, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    Filesearch.create_assistant(params)
  end

  @doc """
  Deletes the Assistant for the given ID
  """
  @spec delete_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any()} | {:error, any()}
  def delete_assistant(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)

    with {:ok, assistant} <- Filesearch.delete_assistant(params.id) do
      {:ok, %{assistant: assistant}}
    end
  end

  @doc """
  Upload and add the files to the VectorStore
  """
  @spec add_assistant_files(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def add_assistant_files(_, params, %{context: %{current_user: user}}) do
    Repo.put_process_state(user.organization_id)
    params = Map.put(params, :organization_id, user.organization_id)

    with {:ok, assistant} <- Filesearch.add_assistant_files(params) do
      {:ok, %{assistant: assistant}}
    end
  end

  @doc """
  Updates an Assistant
  """
  @spec update_assistant(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_assistant(_, %{id: id, input: attrs}, %{context: %{current_user: _user}}) do
    with {:ok, assistant} <- Filesearch.update_assistant(id, attrs) do
      {:ok, %{assistant: assistant}}
    end
  end

  @doc """
  Return the details of the files in a VectorStore
  """
  @spec list_files(VectorStore.t(), map(), map()) :: {:ok, list()}
  def list_files(vector_store, _args, _context) do
    Enum.map(vector_store.files, fn {id, info} ->
      %{id: id, name: info["filename"], uploaded_at: info["uploaded_at"]}
    end)
    |> then(&{:ok, &1})
  end

  @doc """
  Calculate the total file size linked to the VectorStore
  """
  @spec calculate_vector_store_size(VectorStore.t(), map(), map()) :: {:ok, String.t()}
  def calculate_vector_store_size(vector_store, _args, _context) do
    total_size =
      Enum.reduce(vector_store.files, 0, fn {_id, info}, size ->
        size + info["size"]
      end)

    kb = 1_024
    mb = 1_048_576
    gb = 1_073_741_824

    cond do
      total_size >= gb ->
        size = (total_size / gb) |> Float.round(2)
        to_string(size) <> " GB"

      total_size >= mb ->
        size = (total_size / mb) |> Float.round(2)
        to_string(size) <> " MB"

      total_size >= kb ->
        size = (total_size / kb) |> Float.round(2)
        to_string(size) <> " KB"

      true ->
        to_string(total_size) <> " B"
    end
    |> then(&{:ok, &1})
  end
end
