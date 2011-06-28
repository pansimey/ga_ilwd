# -*- coding: utf-8 -*-

require 'MeCab'

class Node
  @@tagger = MeCab::Tagger.new

  attr_reader :prev

  def initialize(node, prev=nil)
    @node = node
    @prev = prev
  end

  def next
    Node.new(@node.next, self)
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

  def self.parse_from(string)
    self.new(@@tagger.parseToNode(string))
  end
end
