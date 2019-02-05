module Errors
  # Errors::AuthErrors
  #
  #   Used to warn about any auth errors, such as empty or not valid access token
  #
  #  TODO : add I18t
  #
  class AuthError < StandardError
    attr_reader :param

    def initialize(param)
      @param = param
      super("Auth error: #{param}")
    end
  end
end