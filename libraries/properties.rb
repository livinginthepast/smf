# Methods to set and delete properties from SMF services
#

module SMFProperties
  # The set of changes to be applied to a service's properties.
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
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, values|
          unless matchprop(group, property, values)
            set_prop(fmri, group, property, values)
            changed = true
          end
        end
      end
      refresh(fmri) if changed
      changed
    end

    def delete_values(fmri)
      changed = false
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, values|
          make_value_array(values).each do |value|
            if matchprop_glob(group, property, value)
              del_prop_value(fmri, group, property, value)
              changed = true
            end
          end
        end
      end
      refresh(fmri) if changed
      changed
    end

    def delete(fmri)
      changed = false
      @existing_xml = read_xml(fmri)
      @groups.each_pair do |group, properties|
        properties.each_pair do |property, _values|
          if prop_exist?(group, property)
            del_prop(fmri, group, property)
            changed = true
          end
        end
      end
      refresh(fmri) if changed
      changed
    end

    private

    def matchprop(group, property, values)
      # Decide if we are looking for a propval or a property with a list of propvals.
      # A property with a single values is specified as a propval node.
      # If a property has a array of values the format is different and a property node is created.
      property_value = propval(group, property)
      if property_value
        return property_value == values
      else
        return prop_exist?(group, property) ? compare_prop_values(group, property, values) : false
      end
    end

    def matchprop_glob(group, property, values)
      # Decide if we are looking for a propval or a property with a list of propvals.
      # A property with a single values is specified as a propval node.
      # If a property has a array of values the format is different and a property node is created.
      property_value = propval(group, property)
      if property_value
        return ::File.fnmatch?(values, property_value)
      else
        return prop_exist?(group, property) ? compare_prop_glob(group, property, values) : false
      end
    end

    def prop_exist?(group, property)
      prop_type(group, property)
    end

    def propval(group, property)
      value = ''
      @existing_xml.elements.each("//property_group[@name='#{group}']//propval[@name='#{property}']") { |element| value = element.attributes['value'] }
      value.empty? ? false : value
    end

    def prop_type(group, property)
      type = ''
      @existing_xml.elements.each("//property_group[@name='#{group}']//property[@name='#{property}']") { |element| type = element.attributes['type'] }
      type.empty? ? false : type
    end

    def read_xml(fmri)
      REXML::Document.new(shell_out!("/usr/sbin/svccfg export #{fmri}").stdout)
    end

    def set_prop(fmri, group, property, values)
      prop_to_set = "#{fmri} setprop #{group}/#{property} = '#{values}'"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_set}")
      Chef::Log.info("Set svc property: #{fmri} #{prop_to_set}")
    end

    def del_prop_value(fmri, group, property, value)
      prop_to_del = "#{fmri} delpropvalue #{group}/#{property} #{value}"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_del}")
      Chef::Log.info("Delete svc property: #{fmri} #{prop_to_del}")
    end

    def del_prop(fmri, group, property)
      prop_to_del = "#{fmri} delprop #{group}/#{property}"
      shell_out!("/usr/sbin/svccfg -s #{prop_to_del}")
      Chef::Log.info("Delete svc property: #{fmri} #{prop_to_del}")
    end

    def refresh(fmri)
      shell_out!("/usr/sbin/svcadm refresh #{fmri}")
      Chef::Log.info("Refresh svc properties: #{fmri}")
    end

    def compare_prop_values(group, property, values)
      # false if anything doesn't match
      match = true
      value_array = make_value_array(values)
      value_index = 0
      @existing_xml.elements.each("//property_group[@name='#{group}']//property[@name='#{property}']//value_node") do |element|
        unless element.attributes['value'] == value_array[value_index]
          match = false
        end
        value_index += 1
        break unless match
      end
      match = false unless value_index == value_array.length
      match
    end

    def compare_prop_glob(group, property, values)
      # true if any match
      value_array = make_value_array(values)
      match = false
      @existing_xml.elements.each("//property_group[@name='#{group}']//property[@name='#{property}']//value_node") do |element|
        value_array.each do |value|
          match = ::File.fnmatch?(value, element.attributes['value'])
          break if match
        end
        break if match
      end
      match
    end

    def make_value_array(values)
      # Transform '("embedded blank" "entry2" "240")'
      # To        ["embedded blank", "entry2", "240"]
      values.gsub(/^\(|\)$/, '').scan(/"([^"]+)"|(\S+)/).flatten.compact
    end
  end
end
