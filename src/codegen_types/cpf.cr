module AST
  class CpfPrimitiveType
    def typescript_decode(expr)
      "#{expr}.replace(/(...)(...)(...)(..)/, \"$1.$2.$3-$4\")"
    end

    def typescript_encode(expr)
      "#{expr}.replace(/[^0-9]/g, \"\").padStart(11, \"0\")"
    end

    def typescript_native_type
      "string"
    end

    def typescript_expect(expr)
      String.build do |io|
        io << "expect(#{expr}).toBeTypeOf(\"string\");\n"
        io << "expect({expr}.replace(/[^0-9]/g, \"\").length).toBe(11);\n"
      end
    end

    def typescript_check_encoded(expr, descr)
      String.build do |io|
        io << "if (#{expr} === null || #{expr} === undefined || typeof #{expr} !== \"string\" || #{expr}.replace(/[^0-9]/g, \"\").length !== 11) {\n"
        io << "    const err = new Error(\"Invalid Type at '\" + #{descr} + \"', expected #{self.class.name}, got '\" + #{expr} + \"'\");\n"
        io << "    typeCheckerError(err, ctx);\n"
        io << "}\n"
      end
    end

    def typescript_check_decoded(expr, descr)
      String.build do |io|
        io << "if (#{expr} === null || #{expr} === undefined || typeof #{expr} !== \"string\" || #{expr}.replace(/[^0-9]/g, \"\").length !== 11) {\n"
        io << "    const err = new Error(\"Invalid Type at '\" + #{descr} + \"', expected #{self.class.name}, got '\" + #{expr} + \"'\");\n"
        io << "    typeCheckerError(err, ctx);\n"
        io << "}\n"
      end
    end

    def kt_decode(expr, desc)
      "#{expr}.getString(#{desc})?.replace(Regex(\"/(...)(...)(...)(..)/\"), \"$1.$2.$3-$4\")"
    end

    def kt_encode(expr, desc)
      "#{expr}.replace(Regex(\"/[^0-9]/g\"), \"\").padStart(11, 0.toChar())"
    end

    def kt_native_type
      "String"
    end

    def kt_return_type_name
      "cpf"
    end
  end
end
