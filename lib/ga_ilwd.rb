# -*- coding: utf-8 -*-

require 'utterance'

class GA_ILWD
  def initialize
    @eliza = Eliza.new
    # TODO
    # DRb.start_service
    # @tuple_space = DRbObject.new_with_uri()
    @last_utterance = nil
    @this_utterance = nil
  end

  def respond(string)
    @user_utterance = Utterance.parse(string)
    learn_from_user
    @this_utterance = @user_utterance.succ
    learn_from_self
    @this_utterance.to_s
  end

  private
  def learn_from_user
    if @last_utterance
      learn(@last_utterance, @user_utterance)
    end
  end

  def learn_from_self
    learn(@user_utterance, @this_utterance)
  end

  def learn(former_utterance, latter_utterance)
    # former = DRbObject.new(former_utterance)
    # latter = DRbObject.new(latter_utterance)
    # @tuple_space.write([:learn, former, latter])
  end
end
