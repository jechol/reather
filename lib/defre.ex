defmodule Defre do
  defmacro __using__(_) do
    quote do
      import Defre, only: :macros
      alias Algae.Reader
    end
  end

  @doc """
  `defre` transforms a function to accept a map where dependent functions and modules can be injected.

      use Defre

      defre send_welcome_email(user_id) do
        %{email: email} = Repo.get(User, user_id)

        welcome_email(to: email)
        |> Mailer.send()
      end

  is expanded into (simplified to understand)

      def send_welcome_email(user_id, deps \\\\ %{}) do
        %{email: email} =
          Map.get(deps, &Repo.get/2,
            :erlang.make_fun(Map.get(deps, Repo, Repo), :get, 2)
          ).(User, user_id)

        welcome_email(to: email)
        |> Map.get(deps, &Mailer.send/1,
            :erlang.make_fun(Map.get(deps, Mailer, Mailer), :send, 1)
          ).()
      end

  Note that local function calls like `welcome_email(to: email)` are not expanded unless it is prepended with `__MODULE__`.

  Now, you can inject mock functions and modules in tests.

      test "send_welcome_email" do
        Accounts.send_welcome_email(100, %{
          Repo => MockRepo,
          &Mailer.send/1 => fn %Email{to: "user100@gmail.com", subject: "Welcome"} ->
            Process.send(self(), :email_sent)
          end
        })

        assert_receive :email_sent
      end

  `defre` raises if the passed map includes a function or a module that's not used within the injected function.
  You can disable this by adding `strict: false` option.

      test "send_welcome_email with strict: false" do
        Accounts.send_welcome_email(100, %{
          &Repo.get/2 => fn User, 100 -> %User{email: "user100@gmail.com"} end,
          &Repo.all/1 => fn _ -> [%User{email: "user100@gmail.com"}] end, # Unused
          strict: false
        })
      end
  """

  defmacro defre(head, body) do
    alias Defre.Inject

    original =
      quote do
        def unquote(head), unquote(body)
      end

    Inject.inject_function(head, body, __CALLER__)
    |> trace(original, __CALLER__)
  end

  defp trace(injected, original, %Macro.Env{file: file, line: line}) do
    if Application.get_env(:defre, :trace, false) do
      dash = "=============================="

      IO.puts("""
      #{dash} defre #{file}:#{line} #{dash}
      #{original |> Macro.to_string()}
      #{dash} into #{dash}"
      #{injected |> Macro.to_string()}
      """)
    end

    injected
  end

  @doc """
  If you don't need pattern matching in mock function, `mock/1` can be used to reduce boilerplates.

      use Defre

      test "send_welcome_email with mock/1" do
        Accounts.send_welcome_email(100) |> Reader.run(
          mock(%{
            &Mailer.send/1 => Process.send(self(), :email_sent)
          })
        )

        assert_receive :email_sent
      end

  Note that `Process.send(self(), :email_sent)` is surrounded by `fn _ -> end` when expanded.
  """
  defmacro mock({:%{}, context, mocks}) do
    alias Defre.Mock

    {:%{}, context, mocks |> Enum.map(&Mock.decorate_with_fn/1)}
  end
end
