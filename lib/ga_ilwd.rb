# -*- coding: utf-8 -*-

lib_dirname = File.dirname(__FILE__) + '/ga_ilwd'
$:.unshift lib_dirname
Dir.open(lib_dirname).each{|item| require item unless item[/^\.+$/]}

class GA_ILWD
  def initialize
    # TODO
    # DRb.start_service
    # @tuple_space = DRbObject.new_with_uri()
    @self_utterances = []
  end

  def respond(string)
    @user_utterance = Utterance.parse(string)
    learn_from_user
    @self_utterances << @user_utterance.succ
    learn_from_self
    @self_utterances.last.to_s
  end

  private
  def learn_from_user
    if @self_utterances.size > 0
      learn(@self_utterances.last, @user_utterance)
    end
    nil
  end

  def learn_from_self
    learn(@user_utterance, @self_utterances.last)
    nil
  end

  def learn(former_utterance, latter_utterance)
    # former = DRbObject.new(former_utterance)
    # latter = DRbObject.new(latter_utterance)
    # @tuple_space.write([:learn, former, latter])
    nil
  end
end
