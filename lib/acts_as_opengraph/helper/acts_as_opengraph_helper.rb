module ActsAsOpengraphHelper
  # Generates the opengraph meta tags for your views
  #
  # @param [Object, #opengraph_data] obj An instance of your ActiveRecord model that responds to opengraph_data
  # @return [String] A set of meta tags describing your graph object based on the {http://ogp.me/ opengraph protocol}
  # @raise [ArgumentError] When you pass an instance of an object that doesn't responds to opengraph_data (maybe you forgot to add acts_as_opengraph in your model)
  # @example
  #   opengraph_meta_tags_for(@movie)
  def opengraph_meta_tags_for(obj, options = {})
    raise(ArgumentError.new, "You need to call acts_as_opengraph on your #{obj.class} model") unless obj.respond_to?(:opengraph_data)


    tags = obj.opengraph_data.map do |att|
			if options.is_a?(Hash)
				key = att[:name].include?("og:") ? att[:name].split("og:")[1] : att[:name]
				if options.include?(key.to_sym)
					att[:value] = options.delete(key.to_sym) 
				end
			end
      att_name = att[:name] == "og:site_name" ? att[:name] : att[:name].dasherize
      %(<meta property="#{att_name}" content="#{Rack::Utils.escape_html(att[:value])}"/>)
    end
		options.each do |key, value|
			tags.push( %(<meta property="og:#{key}" content="#{Rack::Utils.escape_html(value)}"/>))
		end
		tags.push( %(<meta property="fb:app_id" content="#{FACEBOOK_CONFIG[:appId]}"/>))
    tags = tags.join("\n")
    tags.respond_to?(:html_safe) ? tags.html_safe : tags
  end

  # Displays the Facebook Like Button in your views.
  #
  # @param [Object, #opengraph_data] obj An instance of your ActiveRecord model that responds to opengraph_data
  # @param [Hash] options A Hash of {http://developers.facebook.com/docs/reference/plugins/like/ supported attributes}. Defaults to { :layout => :standard, :show_faces => false, :width => 450, :action => :like, :colorscheme => :light }
  # @return [String] An iFrame version of the Facebook Like Button
  # @raise [ArgumentError] When you pass an instance of an object that doesn't responds to opengraph_data (maybe you forgot to add acts_as_opengraph in your model)
  # @example
  #   like_button_for(@movie)
  #   like_button_for(@movie, :layout => :button_count, :display_faces => true)
  # @example Specifying href using rails helpers
  #   like_button_for(@movie, :href => movie_url(@movie))
  def like_button_for(obj, options = {})
    raise(ArgumentError.new, "You need to call acts_as_opengraph on your #{obj.class} model") unless obj.respond_to?(:opengraph_data)
    href = options[:href] ? options[:href] : obj.opengraph_url
    return unless href.present?

    config = { :layout => :standard, :show_faces => false, :width => 450, :action => :like, :colorscheme => :light, :appid => FACEBOOK_CONFIG[:appId], :locale => 'en_US' }
    config.update(options) if options.is_a?(Hash)

    o_layout = config[:layout].to_sym
    if o_layout == :standard
      config[:height] = config[:show_faces].to_s.to_sym == :true ? 80 : 35
    elsif o_layout == :button_count
      config[:height] = 21
    elsif o_layout == :box_count
      config[:height] = 65
    end

    if config[:xfbml]
      like_html = %(<fb:like href="#{CGI.escape(href)}" layout="#{config[:layout]}" show_faces="#{config[:show_faces]}" action="#{config[:action]}" colorscheme="#{config[:colorscheme]}" width="#{config[:width]}" height="#{config[:height]}" font="#{config[:font]}"></fb:like>)
    else
      like_html = %(<iframe src="http://www.facebook.com/plugins/like.php?href=#{CGI.escape(href)}&amp;layout=#{config[:layout]}&amp;show_faces=#{config[:show_faces]}&amp;width=#{config[:width]}&amp;action=#{config[:action]}&amp;colorscheme=#{config[:colorscheme]}&amp;height=#{config[:height]}" scrolling="no" frameborder="0" style="border:none; overflow:hidden; width:#{config[:width]}px; height:#{config[:height]}px;" allowTransparency="true"></iframe>)
    end

		like_html.respond_to?(:html_safe) ? like_html.html_safe : like_html
  end

	def comments_for(obj, options = {})
		raise(ArgumentError.new, "You need to call acts_as_opengraph on your #{obj.class} model") unless obj.respond_to?(:opengraph_data)
    href = options[:href] ? options[:href] : obj.opengraph_url
    return unless href.present?

		config = { :width => 400, :num_posts => 2, :colorscheme => :light, :appid => FACEBOOK_CONFIG[:appId], :locale => 'en_US' }
    config.update(options) if options.is_a?(Hash)

    config[:locale] ||= 'en_US'

    comments_html = %(<div id=\"fb-root\"></div><fb:comments href=\"#{CGI.escape(href)}\" num_posts=\"#{config[:num_posts]}\" width=\"#{config[:width]}\" colorscheme=\"#{config[:colorscheme]}\"></fb:comments>)
  
		comments_html.respond_to?(:html_safe) ? comments_html.html_safe : comments_html
  end

  def fb_javascript_include_tag(appid=FACEBOOK_CONFIG[:appId], locale='en_US')
    async_fb = <<-END
      <div id="fb-root"></div>
      <script>
				FBCallbacks = new [];
				
        window.fbAsyncInit = function() {
          FB.init({appId: '#{ appid }', status: true, cookie: true,
                   xfbml: true});
					
					this.callbacks = new Object();
					this.callbacks.push = function(func){func();};
					for(var i=0; i < FBCallbacks.length; i++)
					{
						FBCallbacks[i]();
					}
					FBCallbacks = this.callbacks;
					
        };
        (function() {
          var e = document.createElement('script'); e.async = true;
          e.src = document.location.protocol +
            '//connect.facebook.net/#{locale}/all.js';
          document.getElementById('fb-root').appendChild(e);
        }());
      </script>
    END
    async_fb.html_safe
  end
end
