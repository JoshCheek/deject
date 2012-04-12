module Deject
  def dependency(name, &blk)
    attr_writer name

    define_method(name) do
      ivar_name = "@#{name}"
      instance_variable_get(ivar_name) ||
        instance_variable_set(ivar_name, self.instance_exec(&blk))
    end
  end
end
