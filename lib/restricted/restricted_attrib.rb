module RestrictedAttrib
 
  ## Class Methods
  module ClassMethods
    def self.extended(base)
       base.before_validation :check_for_restricted_values
    end
  end

  ## Instance Methods
  module InstanceMethods
    # check the changed attributes of a class are restricted or not.
    def check_for_restricted_values
      
      restrict_read_only = self.read_only
      restrict_create_only = self.create_only
      restrict_update_only = self.update_only
      restrict_hidden_only = self.hidden_only
      
      # check for read only attributes
      unless restrict_read_only.blank?
        restrict_read_only.each do |ro|
          if self.changed.include?(ro) || !eval("self.instance_variable_get :@#{ro}").blank?
            self.errors.add(ro.humanize, self.read_only_message)
          end
        end
      end

      # check for create only attributes
      if !restrict_create_only.blank? && !self.new_record?
        restrict_create_only.each do |co|
          if self.changed.include?(co) || !eval("self.instance_variable_get :@#{co}").blank?
            self.errors.add(co.humanize, self.create_only_message)
          end
        end
      end

      # check for update only attributes
      if !restrict_update_only.blank? && self.new_record?
        restrict_update_only.each do |uo|
          if self.changed.include?(uo) || !eval("self.instance_variable_get :@#{uo}").blank?
            self.errors.add(uo.humanize, self.update_only_message)
          end
        end
      end

      # check for hidden only attributes
      if !restrict_hidden_only.blank?
        restrict_hidden_only.each do |ho|
          if self.changed.include?(ho) || !eval("self.instance_variable_get :@#{ho}").blank?
            self.errors.add(ho.humanize, self.hidden_only_message)
          end
        end
      end
      
      # will return validation result
      return false unless self.errors.blank?
    end

    def is_restricted?(action, field, user = nil)
      action = action.to_s
      field = field.to_s
      klass = self.class
      klass_object = self

      unless klass_object.methods.include?("read_only")
         raise NoMethodError, "undefined method `is_restricted?` for #{klass} model. You need to add `has_restricted_method` method in #{klass} model."
      end

      if action.nil? || !['create', 'update', 'read'].include?(action)
        raise ArgumentError, "Invalid action - (#{action}), Pass valid action - :read or :create or :update or 'read' or 'create' or 'update'"
      end

      klass_attributes = klass_object.attributes.keys
      if field.nil? || (!klass_attributes.include?(field) && !klass_object.methods.include?("#{field}="))
        raise ActiveRecord::UnknownAttributeError, "#{klass}: unknown attribute(field): #{field}"
      end

      restrict_read_only = self.read_only
      restrict_create_only = self.create_only
      restrict_update_only = self.update_only
      restrict_hidden_only = self.hidden_only

      if action == "create" || action == "update" || action == "read"
        return true if !restrict_hidden_only.blank? && restrict_hidden_only.include?(field)
      end

      if action == "create" || action == "update"
        return true if !restrict_read_only.blank? && restrict_read_only.include?(field)
      end

      if action == "create"
        return true if !restrict_update_only.blank? && restrict_update_only.include?(field)
      end

      if action == "update"
        return true if !restrict_create_only.blank? && restrict_create_only.include?(field)
      end
      return false
    end

  end
end

