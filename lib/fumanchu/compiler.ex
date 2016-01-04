defmodule FuManchu.Compiler do
  alias FuManchu.Lexer
  alias FuManchu.Parser
  alias FuManchu.Generator

  @type compiled_template :: (map -> String.t)

  @doc """
  Runs a template through the lexer, parser and generator, evaling the
  resulting quoted expression. The resulting function is checked and returned.
  If any steps result in an error, compilation is halted and the error is
  raised.
  """

  @spec compile(String.t) :: {:ok, compiled_template} | {:error, any}
  def compile(source) do
    source
    |> scan
    |> parse
    |> generate
    |> eval
    |> check_fun
  end

  @spec compile!(String.t) :: compiled_template | no_return
  def compile!(source) do
    case compile(source) do
      {:ok, fun} ->
        fun
      {:error, error} ->
        raise error
    end
  end

  defp scan(source) do
    Lexer.scan(source)
  end

  defp parse({:ok, tokens}) do
    Parser.parse(tokens)
  end

  defp parse({:error, error}) do
    {:error, error}
  end

  defp generate({:ok, ast}) do
    Generator.generate(ast)
  end

  defp generate({:error, error}) do
    {:error, error}
  end

  defp eval({:ok, quoted_fun}) do
    Code.eval_quoted(quoted_fun)
  end

  defp eval({:error, error}) do
    {:error, error}
  end

  defp check_fun({fun, []}) when is_function(fun, 1) do
    {:ok, fun}
  end

  defp check_fun({:error, error}) do
    {:error, error}
  end

  defp check_fun(_) do
    {:error, "We didn't get a function like we expected; there's probably a bug in the generator."}
  end
end
