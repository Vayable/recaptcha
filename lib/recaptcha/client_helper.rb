require 'uri'

module Recaptcha
  module ClientHelper
    def recaptcha_key(options = {})
      key = options[:public_key] || Recaptcha.configuration.public_key
      raise RecaptchaError, "No public key specified." unless key
      key
    end

    def recaptcha_iframe_uri(options = {})
      params = URI.encode_www_form(:k => recaptcha_key(options))
      safe_output("#{recaptcha_base_uri(options)}/noscript?#{params}")
    end

    def recaptcha_ajax_uri(options = {})
      safe_output("#{recaptcha_base_uri(options)}/js/recaptcha_ajax.js")
    end

    def recaptcha_challenge_uri(options = {})
      error = options[:error] || ((defined? flash) ? flash[:recaptcha_error] : "")
      lang = options[:display] && options[:display][:lang] ? options[:display][:lang].to_sym : ""
      params = URI.encode_www_form({
                                     :k => recaptcha_key(options),
                                     :error => error,
                                     :lang => lang
                                   }.reject {|k,v| v.nil? })
      safe_output("#{recaptcha_base_uri(options)}/challenge?#{params}")
    end

    def recaptcha_ajax_script_link(options = {})
      javascript_include_tag(recaptcha_ajax_uri(options))
    end

    def recaptcha_challenge_script_link(options = {})
      javascript_include_tag(recaptcha_challenge_uri(options))
    end

    def recaptcha_iframe(options = {})
      html = []
      html << content_tag(:iframe, {
        :src => recaptcha_iframe_uri(options),
        :height => options[:height] || 300,
        :width => options[:width] || 500,
        :style => "border:none;"
      })
      html << "<br/>"
      html << content_tag(:textarea, {
        :name => :recaptcha_challenge_field,
        :rows => options[:textarea_rows] || 3,
        :cols => options[:textarea_cols] || 40
      })
      html << hidden_field_tag(:recaptcha_response_field, :manual_challenge)
      html = html.join
      return (html.respond_to?(:html_safe) && html.html_safe) || html
    end

    def recaptcha_js(options = {})
      ajax_target = options.fetch(:ajax_target, "#dynamic_recaptcha")
      recaptcha_args = ["'#{recaptcha_key(options)}'", "$('#{ajax_target}')[0]"]
      html = []

      if options[:display]
        html << recaptcha_options_js(options[:display])
        recaptcha_args << "RecaptchaOptions"
      end

      html << <<-EOS
        $.getScript('#{recaptcha_ajax_uri(options)}', function() {
          Recaptcha.create(#{recaptcha_args.join(',')});
        });
      EOS

      safe_output(html.join)
    end

    # Your public API can be specified in the +options+ hash or preferably
    # using the Configuration.
    def recaptcha_tags(options = {})
      html  = []

      if options[:ajax]
        html << content_tag(:div, :id => :dynamic_recaptcha)
        html << javascript_tag do
          recaptcha_js(options)
        end
      else
        if options[:display]
          html << javascript_tag do
            recaptcha_options_js(options[:display])
          end
        end

        html << recaptcha_challenge_script_link(options)

        unless options[:noscript] == false
          html << content_tag(:noscript) do
            recaptcha_iframe(options)
          end
        end
      end

      safe_output(html.join)
    end

    ################################################################################
    # protected methods
    ################################################################################
    protected

    def recaptcha_base_uri(options = {})
      Recaptcha.configuration.api_server_url(options[:ssl])
    end

    def recaptcha_options_js(display_options)
      "var RecaptchaOptions = #{display_options.to_json};".html_safe
    end

    def safe_output(html)
      (html.respond_to?(:html_safe) && html.html_safe) || html
    end

  end # ClientHelper
end # Recaptcha
