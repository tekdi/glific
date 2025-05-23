defmodule GlificWeb.Resolvers.Groups do
  @moduledoc """
  Group Resolver which sits between the GraphQL schema and Glific Group Context API. This layer basically stitches together
  one or more calls to resolve the incoming queries.
  """
  use Gettext, backend: GlificWeb.Gettext

  alias Glific.{Groups, Repo}
  alias Glific.Groups.{ContactGroups, Group, UserGroups}

  @doc """
  Get a specific group by id
  """
  @spec group(Absinthe.Resolution.t(), %{id: integer}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def group(_, %{id: id}, _context) do
    {:ok, %{group: Groups.get_group!(id)}}
  rescue
    _ -> {:error, ["Group", dgettext("errors", "Group not found or permission denied.")]}
  end

  @doc """
  Get group info by id
  """
  @spec group_info(Absinthe.Resolution.t(), %{id: integer}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def group_info(_, %{id: id}, _) do
    {:ok, Groups.info_group_contacts(id)}
  end

  @doc """
  Exporting collection details
  """
  @spec export_collection(Absinthe.Resolution.t(), %{id: integer}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def export_collection(_, %{id: id}, _) do
    {:ok, Groups.export_collection(id)}
  end

  @doc """
  Get the list of groups filtered by args
  """
  @spec groups(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, [Group]}
  def groups(_, args, _) do
    {:ok, Groups.list_groups(args)}
  end

  @doc """
  Get the list of contact_groups filtered by args
  """
  @spec contact_groups(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def contact_groups(_, args, _) do
    {:ok, Groups.ContactGroups.list_contact_groups(args)}
  end

  @doc """
  Get the count of contact_groups filtered by args
  """
  @spec count_contact_groups(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, integer}
  def count_contact_groups(_, args, _) do
    {:ok, Groups.ContactGroups.count_contact_groups(args)}
  end

  @doc """
  Get the list of organizations groups filtered by args
  """
  @spec organization_groups(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, [Group]}
  def organization_groups(_, args, _) do
    {:ok, Groups.list_organizations_groups(args)}
  end

  @doc """
  Get the count of groups filtered by args
  """
  @spec count_groups(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, integer}
  def count_groups(_, args, _) do
    {:ok, Groups.count_groups(args)}
  end

  @doc """
  Creates an group
  """
  @spec create_group(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_group(_, %{input: params}, _) do
    with {:ok, group} <- Groups.create_group(params) do
      {:ok, %{group: group}}
    end
  end

  @doc """
  Updates an group
  """
  @spec update_group(Absinthe.Resolution.t(), %{id: integer, input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_group(_, %{id: id, input: params}, %{context: %{current_user: user}}) do
    with {:ok, group} <- Repo.fetch_by(Group, %{id: id, organization_id: user.organization_id}),
         {:ok, group} <- Groups.update_group(group, params) do
      {:ok, %{group: group}}
    end
  end

  @doc """
  Deletes an group
  """
  @spec delete_group(Absinthe.Resolution.t(), %{id: integer}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def delete_group(_, %{id: id}, %{context: %{current_user: user}}) do
    with {:ok, group} <- Repo.fetch_by(Group, %{id: id, organization_id: user.organization_id}) do
      Groups.delete_group(group)
    end
  end

  @doc """
  Get count of group contacts
  """
  @spec contacts_count(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, integer}
  def contacts_count(_, params, _), do: {:ok, Groups.contacts_count(params)}

  @doc """
  Get count of group users
  """
  @spec users_count(Absinthe.Resolution.t(), map(), %{context: map()}) :: {:ok, integer}
  def users_count(_, params, _), do: {:ok, Groups.users_count(params)}

  @doc """
  Get the list of WhatsApp groups filtered by args
  """
  @spec wa_groups_count(Absinthe.Resolution.t(), map(), %{context: map()}) ::
          {:ok, any} | {:error, any}
  def wa_groups_count(_, args, _) do
    {:ok, Groups.wa_groups_count(args)}
  end

  @doc """
  Creates an contact group entry
  """
  @spec create_contact_group(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_contact_group(_, %{input: params}, _) do
    with {:ok, contact_group} <- Groups.create_contact_group(params) do
      {:ok, %{contact_group: contact_group}}
    end
  end

  @doc false
  @spec update_group_contacts(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_group_contacts(_, %{input: params}, _) do
    # we should add sanity check whether group and contact belongs to the organization of the current user
    group_contacts = Groups.GroupContacts.update_group_contacts(params)
    {:ok, group_contacts}
  end

  @doc false
  @spec update_contact_groups(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_contact_groups(_, %{input: params}, _) do
    group_contacts = ContactGroups.update_contact_groups(params)
    {:ok, group_contacts}
  end

  @doc """
  Creates an user group entry
  """
  @spec create_user_group(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def create_user_group(_, %{input: params}, _) do
    with {:ok, user_group} <- Groups.create_user_group(params) do
      {:ok, %{user_group: user_group}}
    end
  end

  @doc false
  @spec update_group_users(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_group_users(_, %{input: params}, _) do
    # we should add sanity check whether group and user belongs to the organization of the current user
    group_users = Groups.GroupUsers.update_group_users(params)
    {:ok, group_users}
  end

  @doc false
  @spec update_user_groups(Absinthe.Resolution.t(), %{input: map()}, %{context: map()}) ::
          {:ok, any} | {:error, any}
  def update_user_groups(_, %{input: params}, _) do
    group_users = UserGroups.update_user_groups(params)
    {:ok, group_users}
  end
end
