require "./token"

class Lexer
  PRIMITIVES = %w[
    bool int uint float string date datetime bytes
    money cpf cnpj email phone cep latlng url
    uuid hex base64 safehtml xml
  ]

  property filename : String

  class LexerException < Exception
  end

  @start_pos = 0
  @start_line = 1
  @start_column = 1
  @line = 1
  @column = 1

  def initialize(string : String, filename : String? = nil)
    @filename = filename || "-"
    @reader = Char::Reader.new(string)
  end

  private def pos
    @reader.pos
  end

  private def current_char
    @reader.current_char
  end

  private def next_char
    @reader.next_char
    @column += 1
    @reader.current_char
  end

  private def peek_next_char
    @reader.peek_next_char
  end

  private def substring(start_pos, end_pos)
    reader = Char::Reader.new(@reader.string)
    reader.pos = start_pos
    String.build do |io|
      while reader.pos <= end_pos
        io << reader.current_char
        reader.next_char
      end
    end
  end

  def next_token
    @start_pos = @reader.pos
    @start_line = @line
    @start_column = @column
    token = nil

    case current_char
    when '\0'
      return nil
    when ' ', '\r', '\t'
      next_char
      return next_token
    when '\n'
      next_char
      @column = 1
      @line += 1
      return next_token
    when '/'
      case next_char
      when '/'
        while true
          case next_char
          when '\0'
            return nil
          when '\n'
            next_char
            @column = 1
            @line += 1
            return next_token
          end
        end
      when '*'
        while true
          case next_char
          when '\n'
            @column = 0
            @line += 1
          when '*'
            while next_char == '*'
            end
            case current_char
            when '\n'
              @column = 0
              @line += 1
            when '\0'
              break
            when '/'
              next_char
              return next_token
            end
          when '\0'
            break
          end
        end
      end
    when '{'
      next_char
      token = CurlyOpenSymbolToken.new
    when '}'
      next_char
      token = CurlyCloseSymbolToken.new
    when '('
      next_char
      token = ParensOpenSymbolToken.new
    when ')'
      next_char
      token = ParensCloseSymbolToken.new
    when '?'
      next_char
      token = OptionalSymbolToken.new
    when ':'
      next_char
      token = ColonSymbolToken.new
    when '!'
      next_char
      token = ExclamationMarkSymbolToken.new
    when ','
      next_char
      token = CommaSymbolToken.new
    when '='
      next_char
      token = EqualSymbolToken.new
    when '['
      case next_char
      when ']'
        next_char
        token = ArraySymbolToken.new
      end
    when '.'
      case next_char
      when '.'
        case next_char
        when '.'
          next_char
          token = SpreadSymbolToken.new
        end
      end
    when '$'
      next_char
      if current_char.ascii_letter?
        while current_char.ascii_letter? || current_char.ascii_number?
          next_char
        end

        token = GlobalOptionToken.new(substring(@start_pos + 1, pos - 1))
      end
    when '"'
      builder = String::Builder.new
      while true
        case next_char
        when '\0'
          break
        when '\\'
          case next_char
          when '\0'
            break
          when 'n' ; builder << '\n'
          when 't' ; builder << '\t'
          when '"' ; builder << '"'
          when '\\'; builder << '\\'
          else
            builder << current_char
          end
        when '"'
          next_char
          token = StringLiteralToken.new(builder.to_s)
          break
        else
          builder << current_char
        end
      end
    else
      if current_char.ascii_letter?
        next_char
        while current_char.ascii_letter? || current_char.ascii_number?
          next_char
        end

        str = substring(@start_pos, pos - 1)

        token = case str
                when "error"   ; ErrorKeywordToken.new
                when "enum"    ; EnumKeywordToken.new
                when "type"    ; TypeKeywordToken.new
                when "import"  ; ImportKeywordToken.new
                when "get"     ; GetKeywordToken.new
                when "function"; FunctionKeywordToken.new
                when "true"    ; TrueKeywordToken.new
                when "false"   ; FalseKeywordToken.new
                else
                  if PRIMITIVES.includes? str
                    PrimitiveTypeToken.new(str)
                  else
                    IdentifierToken.new(str)
                  end
                end
      end
    end

    if token
      token.filename = @filename
      token.line = @start_line
      token.column = @start_column
      return token
    else
      if current_char != '\0'
        raise LexerException.new("Unexpected character #{current_char.inspect} at #{@filename}:#{@line}:#{@column}")
      else
        raise LexerException.new("Unexpected end of file at #{@filename}")
      end
    end
  end
end
