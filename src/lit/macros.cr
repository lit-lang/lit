macro class_property(*property_names)
  {% for prop in property_names %}
    {% prop_name = prop.stringify.split("=").first %}
    @@{{prop}}
    {% pp prop %}

    def self.{{ prop_name }}
      @@{{ prop_name }}
    end

    def self.{{ prop_name }}=({{ prop_name }})
      @@{{ prop_name }} = {{ prop_name }}
    end
  {% end %}
end
