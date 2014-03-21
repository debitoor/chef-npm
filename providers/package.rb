# encoding: utf-8

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def get_npmcmd(args)
  case node[:platform_family]
  when 'windows'
    npmcmd = '"C:/Program files/nodejs/npm"'
  else
    npmcmd = 'npm'
  end
  "#{npmcmd} #{args}"
end


def package_installed(pkg_id, cwd="")
  cdcmd = cwd == "" ?  "" : "cd #{cwd} && "
  npmcmd = get_npmcmd("--no-color -g ls #{pkg_id}")
  cmd = "#{cdcmd}#{npmcmd}"
  p = shell_out(cmd)
  res = /#{pkg_id}/ =~ p.stdout 
  Chef::Log.debug("#{cmd} exitstatus #{p.exitstatus}, output: #{p.stdout}, res: #{res}")
  res
end

use_inline_resources if defined?(use_inline_resources)

action :install do
  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version
  execute "install NPM package #{new_resource.name}" do
    command get_npmcmd("-g install #{pkg_id}")
    not_if {package_installed(pkg_id)}
  end
end

action :install_local do
  path = new_resource.path if new_resource.path
  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version
  execute "install NPM package #{new_resource.name} into #{path}" do
    cwd path
    command get_npmcmd("install #{pkg_id}")
    not_if {package_installed(pkg_id, path)}
  end
end

action :install_from_json do
  path = new_resource.path
  execute "install NPM packages from package.json at #{path}" do
    cwd path
    command get_npmcmd("install")
  end
end

action :uninstall do
  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version
  execute "uninstall NPM package #{new_resource.name}" do
    command get_npmcmd("-g uninstall #{pkg_id}")
    only_if {package_installed(pkg_id)}
  end
end

action :uninstall_local do
  path = new_resource.path if new_resource.path
  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version
  execute "uninstall NPM package #{new_resource.name} from #{path}" do
    cwd path
    command get_npmcmd("uninstall #{pkg_id}")
    only_if {package_installed(pkg_id, path)}
  end
end
