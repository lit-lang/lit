macro token(type)
  Lit::TokenType::{{type}}
end

macro class_property(*property_names)
  {% for prop in property_names %}
    {% prop_name = prop.stringify.split("=").first %}
    @@{{prop}}

    def self.{{ prop_name }}
      @@{{ prop_name }}
    end

    def self.{{ prop_name }}=({{ prop_name }})
      @@{{ prop_name }} = {{ prop_name }}
    end
  {% end %}
end
