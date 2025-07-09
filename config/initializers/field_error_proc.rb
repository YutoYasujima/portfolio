ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
  # inputなどのタグに直接クラスを追加（divで囲まない）
  if html_tag =~ /<(input|textarea|select)/
    html_tag.gsub(/class="/, 'class="field_with_errors ').html_safe
  else
    html_tag
  end
end
