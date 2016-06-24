require 'inflecto'

module DateFormatter
  def self.in_words(timestamp)
    minutes = (((Time.now - timestamp).abs) / 60).round

    return nil if minutes < 0

    case minutes
      when 0..4            then '< 5 minutes'
      when 5..14           then '< 15 minutes'
      when 15..29          then '< 30 minutes'
      when 30..59          then '> 30 minutes'
      when 60..119         then '> 1 hour'
      when 120..239        then '> 2 hours'
      when 240..479        then '> 4 hours'
      when 480..719        then '> 8 hours'
      when 720..1439       then '> 12 hours'
      when 1440..11519     then '> ' << pluralize((minutes/1440).floor, 'day')
      when 11520..43199    then '> ' << pluralize((minutes/11520).floor, 'week')
      when 43200..525599   then '> ' << pluralize((minutes/43200).floor, 'month')
      else                      '> ' << pluralize((minutes/525600).floor, 'year')
    end
  end

  def self.pluralize(n, word)
    if n > 1
      word = Inflecto.pluralize(word)
    end

    "#{n} #{word}"
  end
end
