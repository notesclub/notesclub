defmodule Notesclub.Notebooks.PathsTest do
  use Notesclub.DataCase

  alias Notesclub.Notebooks.Paths

  test "url_to_path/1 with main branch removes /blob/main and .livemd" do
    assert Paths.url_to_path("https://github.com/user/repo/blob/main/sth/whatever.livemd") ==
             "/user/repo/sth/whatever"
  end

  test "url_to_path/1 without main branch does NOT remove /blob/main/ and .livemd" do
    assert Paths.url_to_path("https://github.com/user/repo/blob/master/sth/whatever.livemd") ==
             "/user/repo/blob/master/sth/whatever.livemd"
  end

  test "path_to_url/1 without .livemd adds /blob/main" do
    assert Paths.path_to_url("/user/repo/sth/whatever") ==
             "https://github.com/user/repo/blob/main/sth/whatever.livemd"
  end

  test "path_to_url/1 with .livemd only adds github.com" do
    assert Paths.path_to_url("/user/repo/blob/master/sth/whatever.livemd") ==
             "https://github.com/user/repo/blob/master/sth/whatever.livemd"
  end
end
