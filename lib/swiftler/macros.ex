defmodule Swiftler.Macros do
  @moduledoc """
  Macros for defining Swift functions that can be called from Elixir.
  """

  defmacro swift_function({name, _meta, args} = _signature, do: return_type) when is_atom(name) do
    # Parse the function signature
    {typed_args, _arg_types} = parse_args(args || [])

    # Generate function parameter names for the function definition
    param_names =
      Enum.map(typed_args, fn name ->
        {name, [], nil}
      end)

    quote do
      @swift_functions {unquote(name), unquote(typed_args), unquote(return_type)}

      def unquote(name)(unquote_splicing(param_names)) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end

  defmacro swift_function({:"::", _meta, [{name, _meta2, args}, return_type]})
           when is_atom(name) do
    # Parse the function signature  
    {typed_args, _arg_types} = parse_args(args || [])

    # Generate function parameter names for the function definition
    param_names =
      Enum.map(typed_args, fn name ->
        {name, [], nil}
      end)

    quote do
      @swift_functions {unquote(name), unquote(typed_args), unquote(return_type)}

      def unquote(name)(unquote_splicing(param_names)) do
        :erlang.nif_error(:nif_not_loaded)
      end
    end
  end

  defmacro __before_compile__(env) do
    module = env.module
    swift_functions = Module.get_attribute(module, :swift_functions)

    quote do
      def __swift_functions__, do: unquote(Macro.escape(swift_functions))
    end
  end

  defp parse_args(args) do
    # Handle case where args is nested like [[a: :int, b: :int]]
    parsed =
      case args do
        [keyword_list] when is_list(keyword_list) ->
          # Extract from nested list and check if it's a keyword list
          if Keyword.keyword?(keyword_list) do
            Enum.map(keyword_list, fn {name, type} -> {name, type} end)
          else
            # Handle regular argument list
            Enum.map(keyword_list, fn
              {:"::", _meta, [{var_name, _var_meta, _var_context}, type]} ->
                {var_name, type}

              {var_name, type} when is_atom(var_name) and is_atom(type) ->
                {var_name, type}

              var when is_atom(var) ->
                {var, :term}

              {var_name, _meta, _context} when is_atom(var_name) ->
                {var_name, :term}
            end)
          end

        keyword_list when is_list(keyword_list) ->
          # Check if it's a keyword list
          if Keyword.keyword?(keyword_list) do
            Enum.map(keyword_list, fn {name, type} -> {name, type} end)
          else
            # Handle regular argument list
            Enum.map(keyword_list, fn
              {:"::", _meta, [{var_name, _var_meta, _var_context}, type]} ->
                {var_name, type}

              {var_name, type} when is_atom(var_name) and is_atom(type) ->
                {var_name, type}

              var when is_atom(var) ->
                {var, :term}

              {var_name, _meta, _context} when is_atom(var_name) ->
                {var_name, :term}
            end)
          end

        nil ->
          []

        other ->
          IO.inspect(other, label: "Unexpected args format")
          []
      end

    typed_args = Enum.map(parsed, fn {name, _type} -> name end)
    arg_types = Enum.map(parsed, fn {_name, type} -> type end)

    {typed_args, arg_types}
  end
end
