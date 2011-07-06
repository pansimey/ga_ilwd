# -*- coding: utf-8 -*-

require 'MeCab'

class Node
  @@tagger = MeCab::Tagger.new

  attr_reader :prev

  def initialize(node, prev = nil)
    @node = node.next
    @prev = prev
  end

  def functional_state?
    pos_functional? || suffix_to_functional?
  end

  def to_be_combined?
    sequence_of_functionals? || sequence_of_nouns? ||
      prefix_and_content? || suffix_following?
  end

  private :pos_functional?, :suffix_to_functional?, :pos_suffix?,
    :suffix_following?, :sequence_of_functionals?,
    :sequence_of_nouns?, :prefix_and_content?

  def pos_functional?
    pos == :functional
  end

  def suffix_to_functional?
    @prev && @prev.functional_state? && pos_suffix?
  end

  def pos_suffix?
    [:suffix_noun, :suffix_verb, :suffix_adjv].include?(pos)
  end

  def suffix_following?
    @prev && pos_suffix?
  end

  def sequence_of_functionals?
    functional_state? && @prev.functional_state?
  end

  def sequence_of_nouns?
    @prev && @prev.pos == :noun && pos == :noun
  end

  def prefix_and_content?
    @prev && @prev.pos == :prefix && pos != :functional
  end

  def next
    Node.new(@node.next, self, set_next_state)
  end

  def end_of_sentence?
    @node.feature[/^BOS\/EOS/]
  end

  def surface
    @node.surface.force_encoding('utf-8')
  end

  def feature
    @node.feature.force_encoding('utf-8')
  end

  def conj_type
    case feature.split(',')[4]
    when '*'
      nil
    else
      feature.split(',')[4]
    end
  end

  def conj_form
    case feature.split(',')[5]
    when '*'
      nil
    else
      feature.split(',')[5]
    end
  end

  def infinite
    case feature.split(',')[6]
    when '*'
      surface
    else
      feature.split(',')[6]
    end
  end

  def pos
    case feature[/^([^,]+)/]
    when '名詞'
      if feature[/非自立|特殊,助動詞語幹|接続詞的/]
        :functional
      else
        if feature[/接尾/]
          :suffix_noun
        else
          :noun
        end
      end
    when '接頭詞'
      :prefix
    when '動詞'
      if feature[/非自立/]
        :functional
      else
        if feature[/接尾/]
          :suffix_verb
        else
          :verb
        end
      end
    when '形容詞'
      if feature[/非自立/]
        :functional
      else
        if feature[/接尾/]
          :suffix_adjv
        else
          :adjv
        end
      end
    when '連体詞'
      :adnominal
    when '感動詞'
      :interjection
    when '副詞', '接続詞', '助詞', '助動詞', '記号', 'フィラー', 'その他'
      :functional
    else
      raise 'こんな品詞もありましたよ！：' + feature
    end
  end

  def pos_to_concat
    case pos
    when :suffix_noun
      :noun
    when :suffix_verb
      :verb
    when :suffix_adjv
      :adjv
    when :prefix
      :noun
    else
      pos
    end
  end

  def self.parse_from(string)
    self.new(@@tagger.parseToNode(string))
  end
end
