# encoding: utf-8

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

def whyrun_supported?
  true
end

use_inline_resources if defined?(use_inline_resources)

def get_npmcmd(args)
  case node[:platform_family]
  when 'windows'
    npmcmd = '"C:/Program files/nodejs/npm"'
  else
    npmcmd = 'npm'
  end
  "#{npmcmd} #{args}"
end

def load_current_resource
  @current_resource = Chef::Resource::NpmPackage.new(@new_resource.name)
  @current_resource.name(@new_resource.name)

  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version

  @current_resource.installed = package_installed(pkg_id, @new_resource.path)
  
  Chef::Log.debug("#{pkg_id} installed: #{ @current_resource.installed }")
end

def package_installed(pkg_id, cwd=nil)
  cdcmd = cwd.nil? ?  "" : "cd #{cwd} && "
  global_flag = cwd.nil? ? "-g" : ""
  npmcmd = get_npmcmd("--no-color #{global_flag} ls #{pkg_id}")
  cmd = "#{cdcmd}#{npmcmd}"
  p = shell_out(cmd)
  res = /#{pkg_id}/ =~ p.stdout 
  Chef::Log.debug("#{cmd} exitstatus #{p.exitstatus}, output: #{p.stdout}, res: #{res}")
  res
end

def run_npm(cmd)
  pkg_id = new_resource.name
  pkg_id += "@#{new_resource.version}" if new_resource.version

  if cmd == "install" && new_resource.source_path
    pkg_id = new_resource.source_path
  end
    
  if new_resource.path
    execute "#{cmd} NPM package #{pkg_id} into #{new_resource.path}" do
      cwd new_resource.path
      command get_npmcmd("#{cmd} #{pkg_id}")
    end
  else
    execute "#{cmd} NPM package #{pkg_id}" do
      command get_npmcmd("-g #{cmd} #{pkg_id}")
    end
  end
end

action :install do
  if @current_resource.installed
    Chef::Log.info "#{ @new_resource } already installed - nothing to do."
  else
    converge_by("Install NPM module #{ @new_resource }") do
      run_npm("install")
    end
    @new_resource.updated_by_last_action(true)
  end
end

action :uninstall do
  if @current_resource.installed
    converge_by("Uninstall NPM module #{ @new_resource }") do
      run_npm("uninstall")
    end
    @new_resource.updated_by_last_action(true)
  else
    Chef::Log.info "#{ @new_resource } not installed - nothing to do."
  end
end

action :install_from_json do
  path = new_resource.path
  execute "install NPM packages from package.json at #{path}" do
    cwd path
    command get_npmcmd("install")
  end
end

