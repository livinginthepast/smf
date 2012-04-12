# SMF

## Description

Service Management Facility (SMF) is a tool in Solaris (and Solaris-like
operating systems) for that treats services as first class objects of
the system. It provides an XML syntax for declaring how the system can
interact with an control a service.

The SMF cookbook provides providers for registering a service with SMF.

## Requirements

Any operating system that uses SMF

## Resources and Providers



## Attributes

* `credentials_user` - User to run service commands as
* `start_command`
* `start_timeout`
* `stop_command`
* `stop_timeout`
* `restart_command`
* `restart_timeout`
* `locale` - Character encoding to use (default "C")
* `environment` - Hash - Environment variables to set while running commands


## Usage

    smf "my-service" do
      credentials_user "non-root-user"
      
      start_command "my-service start"
      start_timeout 10
      
      stop_command "pkill my-service"
      stop_command  5
      
      restart_command "my-service restart"
      restart_timeout 60
      
      environment "PATH" => "/home/non-root-user/bin",
                  "RAILS_ENV" => "staging"
      
      locale "C"
      
      manifest_type "application"
      service_path  "/var/svc/manifest"
    end
    
    service "my-service" do
      action :enable
    end
    
    service "my-service" do
      action :restart
    end
