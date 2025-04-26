defmodule Notesclub.XPITest do
  use Notesclub.DataCase

  import Mock
  alias Notesclub.X

  describe "X API V2 authentication" do
    test "get_authorize_url/0 returns X API V2 oauth2 authorize url" do
      assert X.get_authorize_url() ==
               "https://twitter.com/i/oauth2/authorize?client_id=123&code_challenge=challenge&code_challenge_method=plain&redirect_uri=https%3A%2F%2Flocalhost%3A4000%2Fcallback&response_type=code&scope=tweet.read%2Busers.read%2Btweet.write%2Boffline.access&state=state"
    end
  end
end
