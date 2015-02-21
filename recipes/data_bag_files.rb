#
# Cookbook Name:: user
# Recipe:: data_bag
#
# Copyright 2013, RelateIQ Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

user_bag = node['user']['data_bag_name']
file_bag = node['user']['data_bag_name_files']

# Fetch the user array from the node's attribute hash. If a subhash is
# desired (ex. node['base']['user_accounts']), then set:
#
#     node['user']['user_array_node_attr'] = "base/user_accounts"
user_array = node
node['user']['user_array_node_attr'].split("/").each do |hash_key|
  user_array = user_array.send(:[], hash_key)
end

# only manage the subset of users defined
Array(user_array).each do |i|
  u = data_bag_item(user_bag, i.gsub(/[.]/, '-'))
  username = u['username'] || u['id']

	user_files_bag = data_bag(file_bag)
	if user_files_bag.include?(username)
		files = data_bag_item(file_bag, username);
		files.to_hash.select{|k,v| not ['id','chef_type','data_bag'].include?(k)}.map do |key, value|
			file "/home/#{username}/#{key}" do
				owner username
				content Base64.decode64(value)
			end
		end
	end

	bash "include_global_bashrc_#{username}" do
		code <<-EOC
			echo "if [ -f /etc/bashrc ] && [ -d /home/#{username} ]; then . /etc/bashrc; fi" >> /home/#{username}/.bashrc
		EOC
		not_if "grep -q /etc/bashrc /home/#{username}/.bashrc"
	end
end
