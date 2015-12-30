defmodule FuManchu.Compiler do
  alias FuManchu.Lexer
  alias FuManchu.Parser
  alias FuManchu.Generator

  @type compiled_template :: (map -> String.t)

  @spec compile!(String.t) :: compiled_template | no_return
  def compile!(source) do
    source
    |> scan
    |> parse
    |> generate
    |> eval
    |> check_fun
  end

  defp scan(source) do
    Lexer.scan(source)
  end

  defp parse({:ok, tokens}) do
    Parser.parse(tokens)
  end

  defp parse({:error, error}) do
    raise error
  end

  defp generate({:ok, ast}) do
    Generator.generate(ast)
  end

  defp generate({:error, error}) do
    raise error
  end

  defp eval({:ok, quoted_fun}) do
    Code.eval_quoted(quoted_fun)
  end

  defp eval({:error, error}) do
    raise error
  end

  defp check_fun({fun, []}) when is_function(fun, 1) do
    fun
  end

  defp check_fun(_) do
    raise "We didn't get a function like we expected; there's probably a bug in the generator."
  end
end
