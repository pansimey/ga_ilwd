# -*- coding: utf-8 -*-

require 'MeCab'

class GA_ILWD
  class Eliza
    def respond(string)
      # TODO
      'わかりません。'
    end
  end

  def initialize
    @tagger = MeCab::Tagger.new
    @eliza = Eliza.new
    # TODO
    # @tuple_space = DRbObject.new_with_uri()
    @last_response_id = nil
    @this_response_id = nil
  end

  def respond(string)
    initialize_state!
    parse_to_node(string)
    while next_node?
      if end_of_sentence?
        finalize!
        break
      end
      set_new_pos
      if chunkable?
        update
      else
        concat
      end
    end
    # 順序を含めて100％合致の内容語列がなければ新規内容語列
    content_ids = nil
    @contents.each_with_index do |content, index|
      content_patterns =
        ContentPattern.where(
          order:index+1,
          infinite:content[:infinite],
          pos:content[:pos],
          conj_type:content[:conj_type]
        ).all
      new_content_ids = content_patterns.map{|pattern| pattern.pattern_id}
      if content_ids.nil?
        content_ids = new_content_ids
      else
        content_ids = content_ids & new_content_ids
      end
      break if content_ids.size == 0
    end
    # 表層文生成ルールに保存
    # if @last_response_id
    #   応答文生成S->Uルールに保存
    # end
    # 65％以上合致の内容語列が
    # - あればGA-IL応答出力
    # - なければEliza
    # 応答文生成U->Sルールに保存
  end

  private
  def single_pattern_exists?(content)
    content_patterns =
      ContentPattern.where(order:1, count:1).all.
                     where(word:content[:infinite], pos:content[:pos]).all.
                     where(type:content[:conj_type])
  end

  def initialize_state!
    @surface = ''
    @infinite = ''
    @last_pos = nil
    @curr_pos = nil
    @prev_form = nil
    @conj_type = nil
    @conj_form = nil
    @contents = []
    @functionals = []
  end

  def parse_to_node(string)
    @node = @tagger.parseToNode(string)
  end

  def next_node?
    @node = @node.next
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

  def functional_state?
    @functionals.size == @contents.size
  end

  def concat
    @current_pos =
      case @new_pos
      when :suffix_noun
        :noun
      when :suffix_verb
        :verb
      when :suffix_adjv
        :adjv
      when :prefix
        :noun
      else
        @new_pos
      end
    @infinite = @surface + infinite
    @surface << surface
    @conj_type = conj_type
    @conj_form = conj_form
  end

  def update
    if functional_state?
      @functionals << {surface:@surface, prev_form:@prev_form}
    else
      @contents << {infinite:@infinite, pos:@current_pos, conj_type:@conj_type}
      @functionals << {surface:'', prev_form:nil} unless @new_pos == :functional
    end
    @surface = surface
    @infinite = infinite
    @current_pos = @new_pos
    @conj_type = conj_type
    @prev_form = @conj_form
    @conj_form = conj_form
  end

  def finalize!
    if functional_state?
      @functionals << {surface:@surface, prev_form:@prev_form}
    else
      @contents << {infinite:@infinite, pos:@last_pos, conj_type:@conj_type}
      @functionals << {surface:'', prev_form:nil}
    end
  end

  def chunkable?
    if @new_pos == :functional
      if functional_state?
        false
      else
        true
      end
    else
      if functional_state?
        case @new_pos
        when :suffix_noun, :suffix_verb, :suffix_adjv
          false
        else
          true
        end
      elsif @current_pos == :noun && @new_pos == :noun
        false
      elsif @current_pos == :prefix
        false
      else
        case @new_pos
        when :suffix_noun, :suffix_verb, :suffix_adjv
          false
        else
          true
        end
      end
    end
  end

  def set_new_pos
    @new_pos =
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

  def eliza_respond(string)
    @eliza.respond(string)
  end
end
