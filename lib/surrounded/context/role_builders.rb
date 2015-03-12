module Surrounded
  module Context
    module RoleBuilders

      # Define behaviors for your role players
      def role(name, type=default_role_type, &block)
        if type == :module
          mod_name = ModuleName(name)
          mod = Module.new(&block).send(:include, ::Surrounded)
          private_const_set(mod_name, mod)
        else
          meth = method(type)
          meth.call(name, &block)
        end
      rescue NameError => e
        raise e.extend(InvalidRoleType)
      end
      alias_method :role_methods, :role

      # Create a named behavior for a role using the standard library SimpleDelegator.
      def wrap(name, &block)
        require 'delegate'
        wrapper_name = ModuleName(name)
        klass = private_const_set(wrapper_name, Class.new(SimpleDelegator, &block))
        klass.send(:include, Surrounded)
      end
      alias_method :wrapper, :wrap

      # Create a named behavior for a role using the standard library DelegateClass.
      # This ties the implementation of the role to a specific class or module API.
      def delegate_class(name, class_name, &block)
        require 'delegate'
        wrapper_name = ModuleName(name)
        klass = private_const_set(wrapper_name, DelegateClass(Object.const_get(class_name.to_s)))
        klass.class_eval(&block)
        klass.send(:include, Surrounded)
      end

      # Create an object which will bind methods to the role player
      def interface(name, &block)
        # AdminInterface
        interface_name = ModuleName(name, 'Interface')
        behavior = private_const_set(interface_name, Module.new(&block))

        require 'surrounded/context/negotiator'
        undef_method(name)

        # AdminInterfaceProxy
        proxy = private_const_set(ModuleName(interface_name, 'Proxy'), Negotiator.for_role(behavior))
        define_method(name) do
          instance_variable_set("@#{name}", proxy.new(role_map.assigned_player(name), behavior))
        end
      end
      
      private
      def ModuleName(text, suffix=nil)
        ModuleName.new(text, suffix)
      end

    end
  end
end