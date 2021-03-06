require "restricted/restricted_attrib"

module SimpleRestrictedAttributes

  module Restricted

    def has_restricted_attributes(options = {})
      cattr_accessor :read_only, :create_only, :update_only, :hidden_only
      cattr_accessor :read_only_message, :create_only_message, :update_only_message, :hidden_only_message
      
      # set the read only attributes of a class
      if options[:read_only]
        only_read = []
        if options[:read_only].is_a?(Array)
          only_read = options[:read_only].collect {|r| r.to_s }
        else
          only_read << options[:read_only].to_s
        end
        self.read_only = only_read
      end

      # set the create only attributes of a class
      if options[:create_only]
        only_create = []
        if options[:create_only].is_a?(Array)
          only_create = options[:create_only].collect {|c| c.to_s }
        else
          only_create << options[:create_only].to_s
        end
        self.create_only = only_create
      end

      # set the create only attributes of a class
      if options[:update_only]
        only_update = []
        if options[:update_only].is_a?(Array)
          only_update = options[:update_only].collect {|u| u.to_s }
        else
          only_update << options[:update_only].to_s
        end
        self.update_only = only_update
      end

      # set the hidden only attributes of a class
      if options[:hidden_only]
        only_hidden = []
        if options[:hidden_only].is_a?(Array)
          only_hidden = options[:hidden_only].collect {|u| u.to_s }
        else
          only_hidden << options[:hidden_only].to_s
        end
        self.hidden_only = only_hidden
      end

      # Default validation messages
      ro_msg = "is a read only attribute."
      co_msg = "can't update, its permitted to create only."
      uo_msg = "can't add, its permitted to update only."
      ho_msg = "is a hidden attribute."

      # assign validation messages to restricted attributes
      self.read_only_message = options[:read_only_message] ? options[:read_only_message].to_s : ro_msg
      self.create_only_message = options[:create_only_message] ? options[:create_only_message].to_s : co_msg
      self.update_only_message = options[:update_only_message] ? options[:update_only_message].to_s : uo_msg
      self.hidden_only_message = options[:hidden_only_message] ? options[:hidden_only_message].to_s : ho_msg

      extend RestrictedAttrib::ClassMethods
      include RestrictedAttrib::InstanceMethods      
    end    
  end

  module RestrictedHelpers
    def is_restricted?(klass, action, field, user = nil)
      action = action.to_s
      field = field.to_s
      raise ArgumentError, "Must pass valid class" if klass.nil? || !klass.is_a?(Class)

      klass_object = klass.new

      unless klass_object.methods.include?("read_only")
         raise NoMethodError, "undefined method `is_restricted?` for #{klass} model. You need to add `has_restricted_attributes` method in #{klass} model."
      end
      
      if action.nil? || !['create', 'update', 'read'].include?(action)
        raise ArgumentError, "Invalid action - (#{action}), Pass valid action - :read or :create or :update or 'read' or 'create' or 'update'"
      end

      klass_attributes = klass_object.attributes.keys
      if field.nil? || !klass_attributes.include?(field)
        raise ActiveRecord::UnknownAttributeError, "#{klass}: unknown attribute(field): #{field}"
      end

      restrict_read_only = klass_object.read_only
      restrict_create_only = klass_object.create_only
      restrict_update_only = klass_object.update_only
      restrict_hidden_only = klass_object.hidden_only

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

ActiveRecord::Base.send(:extend, SimpleRestrictedAttributes::Restricted)
ActionView::Base.send(:include, SimpleRestrictedAttributes::RestrictedHelpers)
ActionController::Base.send(:include, SimpleRestrictedAttributes::RestrictedHelpers)