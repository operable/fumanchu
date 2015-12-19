defmodule FuManchu.Compiler do
  alias FuManchu.Lexer
  alias FuManchu.Parser
  alias FuManchu.Generator

  def compile(source) do
    {:ok, tokens} = Lexer.tokenize(source)
    {:ok, ast}    = Parser.parse(tokens)
    quoted_fun    = Generator.generate(ast)
    {fun, []}     = Code.eval_quoted(quoted_fun)
    fun
  end
end
