require 'iconv'

class Griddler::Email
  attr_accessor :to, :from, :body, :user, :comment

  def initialize(params)
    extract_ivars(params)
    {
      to: @to,
      from: @from,
      subject: @subject,
    }
  end

  private

  def extract_ivars(params)
    @to   = retrieve_to_address(params)
    @from = extract_token(params[:from])
    @subject = params[:subject]

    if params[:charsets]
      charsets = ActiveSupport::JSON.decode(params[:charsets])
      @body = extract_reply_body(Iconv.new('utf-8', charsets['text']).iconv(params[:text]))
    else
      @body = extract_reply_body(params[:text])
    end
  end

  def retrieve_to_address(params)
    parsed = EmailParser.parse(params[:to])
    if config.to == :hash
      parsed
    else
      parsed[config.to]
    end
  end

  def extract_token(address)
    if address
      address = address.split('<').last
      if matches = address.match(Griddler::EmailFormat::Regex)
        address = matches[0]
      end
    end
    address # => token
  end

  def extract_reply_body(body)
    if body
      delimeter = config.reply_delimiter
      body.split(delimeter).first.
        split(/^\s*[-]+\s*Original Message\s*[-]+\s*$/).first.
        split(/^\s*--\s*$/).first.
        split(/[\r]*\n/).reject { |line|
        line =~ /^\s*>/ || line =~ /^\s*On.*wrote:$/ || line =~ /^\s*Sent from my /
      }.join("\n").gsub(/^\s*On.*\r?\n?\s*.*\s*wrote:$/,'').strip
    end
  end

  private

  def config
    Griddler.configuration
  end
end
