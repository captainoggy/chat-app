class AllowUserLocaleEnabledValidator

  def initialize(opts={})
    @opts = opts
  end

  def valid_value?(val)
    # only validate when enabling setting locale from headers
    return true if val == "f"
    # ensure that allow_user_locale is enabled
    SiteSetting.allow_user_locale
  end

  def error_message
    "You must first enable 'allow user locale' before enabling this setting."
  end

end