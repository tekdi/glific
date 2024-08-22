defmodule GlificWeb.Schema.OpenAITypes do
  @moduledoc """
  GraphQL Representation of Glific's OpenAI DataType
  """
  use Absinthe.Schema.Notation

  alias GlificWeb.Resolvers
  alias GlificWeb.Schema.Middleware.Authorize

  object :vector_store do
    field :name, :string
    field :vector_store_id, :string
  end

  object :assistant do
    field :name, :string
    field :description, :string
    field :instructions, :string
    field :vector_store_id, :string
    field :model, :string
    field :assistant_id, :string
  end

  object :openai_mutations do
    @desc "Create vector store"
    field :create_vector_store, :vector_store do
      arg(:name, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.create_vector_store/3)
    end

    @desc "Modify vector sotre"
    field :modify_vector_store, :vector_store do
      arg(:vector_store_id, non_null(:string))
      arg(:name, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.modify_vector_store/3)
    end

    @desc "Delete vector store"
    field :delete_vector_store, :vector_store do
      arg(:vector_store_id, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.delete_vector_store/3)
    end

    @desc "Create Assistant"
    field :create_assistant, :assistant do
      arg(:name, non_null(:string))
      arg(:model, non_null(:string))
      arg(:description, non_null(:string))
      arg(:instructions, non_null(:string))
      arg(:vector_store_id, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.create_assistant/3)
    end

    @desc "Modify Assistant"
    field :modify_assistant, :assistant do
      arg(:assistant_id, non_null(:string))
      arg(:name, non_null(:string))
      arg(:model, non_null(:string))
      arg(:description, non_null(:string))
      arg(:instructions, non_null(:string))
      arg(:vector_store_id, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.modify_assistant/3)
    end

    @desc "Delete assistant"
    field :delete_assistant, :assistant do
      arg(:assistant_id, non_null(:string))
      middleware(Authorize, :staff)
      resolve(&Resolvers.OpenAI.delete_assistant/3)
    end
  end
end
