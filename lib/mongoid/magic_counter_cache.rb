require 'mongoid'
module Mongoid #:nodoc:

  # The Counter Cache will yada yada
  #
  #    class Person
  #      include Mongoid::Document
  #
  #      field :name
  #      field :feeling_count
  #      field :last_feeling_at
  #      has_many :feelings
  #    end
  #
  #    class Feeling
  #      include Mongoid::Document
  #      include Mongoid::MagicCounterCache
  #
  #      field :name
  #      belongs_to    :person
  #      counter_cache :person
  #    end
  #
  # Alternative Syntax
  #
  #    class Person
  #      include Mongoid::Document
  #
  #      field :name
  #      field :all_my_feels_count
  #      field :last_all_my_feels_at
  #      has_many :feelings
  #    end
  #
  #    class Feeling
  #      include Mongoid::Document
  #      include Mongoid::MagicCounterCache
  #
  #      field :name
  #      belongs_to    :person
  #      counter_cache :person, :using => "all_my_feels"
  #    end
  module MagicCounterCache
    extend ActiveSupport::Concern

    module ClassMethods

      def counter_cache(*args, &block)
        options = args.extract_options!
        name    = options[:class] || args.first.to_s
        modulus = options[:using] ? options[:using].to_s : model_name.demodulize.underscore
        counter_name = "#{modulus}_count"
        last_at_name = "last_#{modulus}_at"

        after_create  do |doc|
          if doc.embedded?
            parent = doc._parent
            parent.inc(counter_name.to_sym, 1) if parent.respond_to? counter_name
          else
            relation = doc.send(name)
            if relation and field_keys = relation.class.fields.keys
              if field_keys.include?(counter_name)
                relation.inc(counter_name.to_sym, 1)
              end
              if field_keys.include?(last_at_name)
                relation.touch(last_at_name.to_sym)
              end
            end
          end
        end

        after_destroy do |doc|
          if doc.embedded?
            parent = doc._parent
            parent.inc(counter_name.to_sym, -1) if parent.respond_to? counter_name
          else
            relation = doc.send(name)
            if relation and relation.class.fields.keys.include?(counter_name)
              relation.inc(counter_name.to_sym, -1)
            end
          end
        end

      end

      alias :magic_counter_cache :counter_cache
    end

  end
end
