# Labelize
# 
# 
# Allows for a one sided one-to-one association where the database column
# resides on the "parent" table.  This would be most commonly used to label a 
# single instance out of a associated collection.  However, there is no
# restriction on the association and it can be used without an accompanying
# one-to-many or many-to-many association.  It simply is a way to tag some
# other model instance as an association with a specified label.
# 
# 
# Example:
#  
#   class Company < ActiveRecord::Base
#     
#     has_many :employees
#     label_one_of_many :employees, :as => [ :president, :manager, :janitor ] 
#     
#   end
#
module Labelize
  
  VERSION = "0.9"
  
  def self.included(base) # :nodoc:
    base.send :extend, ClassMethods
  end 
  
  # Class methods to be included into ActiveRecord::Base.  To be called by
  # models to add Labelize functionallity to model.
  module ClassMethods
    # Called as macro with and argument of the table name of the model to be labelled
    # as a sybmol.  More or less like you would use a standard association call like
    # has_many.  An option <tt>:as</tt> is provided to define the label names.  Multiple labels
    # can be defined in an array and label can be a string or a symbol.  If an <tt>:as</tt>
    # option is not provided, the label will default to the singular inflection of 
    # the association's table name.
    #
    # *Examples*:
    #
    #   class Company < ActiveRecord::Base
    #     label_one_of_many :employees, :as => 'manager'
    #   end
    #
    #   class Company < ActiveRecord::Base
    #     label_one_of_many :employees, :as => :manager
    #   end
    #
    #   class Company < ActiveRecord::Base
    #     label_one_of_many :employees, :as => ['manager', :president]
    #   end
    #
    # If id is valid, return object.
    # If id is invalid, write id as nil and returns, <tt>nil</tt>.
    # If no id is set, returns <tt>nil</tt>.
    def label_one_of_many(association_id, options = {})
      options.assert_valid_keys(:as)

      # puts options[:as]
      puts get_labels(options[:as]).size

      get_labels(options[:as]).each do |label_id|
        define_label_methods(association_id, label_id)
      end
    end
    
    # Called by #label_one_of_many to define instance methods
    def define_label_methods(association_id, label_id)
      klass = association_id.to_s.classify.constantize
        
      # Defines labelled getter method
      define_method "#{label_id}" do
        if !read_attribute("#{label_id}_id").blank?
          begin
            klass.find(read_attribute("#{label_id}_id"))
         rescue ActiveRecord::RecordNotFound => error
            write_attribute("#{label_id}_id", nil)
          end
        else
          nil
        end
      end
      
      # Defines labelled setter method
      define_method "#{label_id}=" do |new_association|
        case new_association
        when Fixnum, String
          write_attribute("#{label_id}_id", new_association)
        else
          write_attribute("#{label_id}_id", new_association.id)
        end
      end
        
    end
    
    # Called by #define_label_methods to unify <tt>:as</tt> argument into an array of strings
    def get_labels(label_ids)
      labels = []
      labels.push(label_ids).flatten!
      labels.map! { |label_id| label_id.to_s }
    end

  end
end

if Object.const_defined?("ActiveRecord") # :nodoc:
  ActiveRecord::Base.send(:include, Labelize)
end
