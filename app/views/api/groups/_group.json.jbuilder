# frozen_string_literal: true

json.extract! group, :id, :slug, :name, :disabled
# Members count is admin/manager metadata — never expose to anonymous callers
# (signup modal) nor to regular members. See API::GroupsController#index.
json.users group.users.count unless @restricted_groups_index
