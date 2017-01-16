require File.expand_path '../../../test_helper.rb', __FILE__

class Events::BaseTest < MiniTest::Test
  def test_merge_commits
    assert_equal proper_commits, Events::Base.new.send(:merge_commits, get_commits)
  end

  def get_commits
    proper_commits + unproper_commits
  end
  def proper_commits
    message_1 = <<'EOS'
Merge pull request #1234 from jabropt/fix/hogehoge

Hello world!
EOS
    message_2 = <<'EOS'
Merge pull request #5678 from jabropt/fix/hogehoge

Add new world!
EOS
    [
      {'commit' => {'message' => message_1}},
      {'commit' => {'message' => message_2}}
    ]
  end

  def unproper_commits
    message_1 = 'hogehoge'
    message_2 = 'Merge pull request #5678 from jabropt/fix/hogehoge'
    [
      {'commit' => {'message' => message_1}},
      {'commit' => {'message' => message_2}}
    ]
  end
end
