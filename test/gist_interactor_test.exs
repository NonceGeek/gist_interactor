defmodule GistInteractorTest do
  use ExUnit.Case
  doctest GistInteractor

  test "greets the world" do
    assert GistInteractor.hello() == :world
  end
end
