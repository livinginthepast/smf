# Methods to set and delete properties from SMF services
#

module SMFProperties
  # The set of changes to be applied to properties.
  class Changes
    require 'rexml/document'
    require 'chef/mixin/shell_out'
    include Chef::Mixin::ShellOut

    public

    def initialize(groups)
      @groups = groups
    end

    def set(fmri)
      changed = false
      @existing_xml = REXML::Document.new
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, values|
          unless matchprop(group, property, values)
            setprop(fmri, group, property, values)
            changed = true
          end
        end
      end
      refresh(fmri) if changed
      changed
    end

    def delete_values(fmri)
      changed = false
      @existing_xml = REXML::Document.new
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, values|
          make_value_array(values).each do |value|
            # TODO the value specified for delpropvalue is a glob pattern
            # The matching needs to change.  ::FILE has a glob match a string method
            if matchprop(group, property, value)
              delprop_value(fmri, group, property, value)
              changed = true
            end
          end
        end
      end
      refresh(fmri) if changed
    end

    def delete(fmri)
      changed = false
      @existing_xml = REXML::Document.new
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, values|
          if prop_type(group, property)
            delprop(fmri, group, property)
            changed = true
          end
        end
      end
      refresh(fmri) if changed
    end

    private

    def matchprop(group, property, values)
      # Using @existing_xml
      # Decide if we are looking for a propval or a property with a list of propvals.
      # A property with a single values is specified as a propval node.
      # If a property has a array of values the format is different and a property node is created.
      property_value = propval(group, property)
      if property_value
        return property_value == values
      else
        property_type = prop_type(group, property)
        return property_type ? compare_prop_values(group, property, values) : false
      end
    end

    def propval(group, property)
      @existing_xml.elements.each("//property_group[@name='#{group}']//propval[@name='#{property}']") { |element| element.attributes['value'] }
    end

    def prop_type(group, property)
      @existing_xml.elements.each("//property_group[@name='#{group}']//property[@name='#{property}']") { |element| element.attributes['type'] }
    end

    def read_xml(fmri)
      REXML::Document.new(shell_out!("/usr/sbin/svccfg export #{fmri}").stdout)
    end

    def setprop(fmri, group, property, values)
      prop_to_set = "#{fmri} setprop #{group}/#{property} = '#{values}'"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_set}")
      Chef::Log.info("Set svc property: #{fmri} #{prop_to_set}")
    end

    def delprop_value(fmri, group, property, value)
      prop_to_del = "#{fmri} delpropvalue #{group}/#{property} #{value}"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_del}")
      Chef::Log.info("Set svc property: #{fmri} #{prop_to_del}")
    end

    def delprop(fmri, group, property)
      prop_to_del = "#{fmri} delprop #{group}/#{property}"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_del}")
      Chef::Log.info("Delete svc property: #{fmri} #{prop_to_del}")
    end

    def refresh(fmri)
      shell_out!("/usr/sbin/svcadm refresh #{fmri}")
      Chef::Log.info("Refresh svc properties: #{fmri}")
    end

    def compare_prop_values(group, property, values)
      value_array = make_value_arrary(values)
      value_index = 0
      match = true
      @existing_xml.elements.each("//property_group[@name='#{group}']//property[@name='#{property}']") do |element|
        unless element.attributes['value'] == value_array[value_index]
          match = false
          value_index += 1
        end
        match = false unless value_index == array.length
        break unless match
      end
    end

    def make_value_array(values)
      %W(#{values.gsub(/^\(|\)$/, '')})
    end
  end
end
