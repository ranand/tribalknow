
module ApplicationHelper
  def render_md(text)
    GitHub::Markdown.render_gfm(sanitize(text)).html_safe
  end

  def render_avatar user, options = {}
    return unless user

    if user.avatar?
      opts = if options[:size]
        size = options[:size].to_s =~ /x/ ? options[:size] : "#{options[:size]}x#{options[:size]}"
        { :size => size }
      else
        {}
      end
      image_tag user.avatar.url(:thumb), opts.merge(:class=>'avatar')
    else
      render_gravatar user, options
    end
  end

  def gravitar_url user, opt_string = ""
    "#{request.protocol}www.gravatar.com/avatar/#{Digest::MD5.hexdigest(user.email.strip.downcase)}#{opt_string}"
  end

  def render_gravatar user, options = {}
    if user
      opt_string = "?s=#{options[:size]}" if options[:size]
      image_tag(gravitar_url(user, opt_string), :alt=>"Your avatar", :class=>'avatar')
    else
      size = "40x40"
      size = "#{options[:size]}x#{options[:size]}" if options[:size]
      image_tag("#{request.protocol}placehold.it/#{size}", :class=>'avatar')
    end
  end

  def render_tag_links tags, options={}
    tags.map do |tag|
      link_to tag, questions_path(:tag=>tag.name), :class=>'taglink'
    end.join(' ').html_safe
  end

  def smart_display(obj, options={})
    case obj
    when Time, DateTime
      if (obj+1.day).future?  # very recent
        l(obj, :format=>:short)
      elsif (DateTime.now - 8.months) < obj  # medium.  show month, day
        l(obj, :format=>:monthday)
      else # really old, show year
        l(obj, :format=>:onlydate)
      end
    else
      obj
    end
  end

  def asked_by obj
    render :partial=>'/shared/asked_by', :locals=>{:user=>obj.creator, :at => obj.created_at }
  end

  def answered_by obj
    render :partial=>'/shared/answered_by', :locals=>{:user=>obj.creator, :at => obj.created_at }
  end

  def render_tags
    
  end

  # foundation icon generate
  def f_icon name, options={}
    css_class = ["fi-#{name}", options[:class]].join(" ").strip
    if options[:color]
      options[:style] = [ "color:#{options[:color]}", options[:style] ].join(";").strip
      options.delete(:color)
    end
    if options[:size]
      options[:style] = [ "font-size:#{options[:size]}", options[:style] ].join(";").strip
      options.delete(:size)
    end
    content_tag(:i, nil, options.merge(:class=>css_class))
  end

  def best_in_place_with_edit_icon obj, method, opts = {}
    # this is a wip.  started using it but wasn't happy with it, so i need to circle back later
    edit_content_id = dom_id(obj, method)

    addl_options = { :activator => "##{edit_content_id}" }

    rv = best_in_place obj, method, opts.merge(addl_options)
    rv << f_icon('pencil', :id=>edit_content_id, :class=>'edit_icon_right')

    rv.html_safe
  end

  def in_place_edit_panel note, path
    title = content_tag(:h3, best_in_place(note, :title,{ :as=>:input, :raw=>true }))

    edit_content_id = dom_id(note, :content)
    content = best_in_place(note, :content, {:as=>:textarea, :raw=>true, :activator=>"##{edit_content_id}", :display_with=>lambda{ |content| content.to_s.html_safe}})
    edit_icon = f_icon('pencil', :id=>edit_content_id, :class=>'edit_icon')

    content_tag(:div, "#{title} #{content} &nbsp;#{edit_icon}".html_safe, :class=>'panel')
  end

  # display a series of panels per controller/action
  def local_notes options = {}
    # if user is creator or admin, add link to admin
    allow_admin = !options[:disable_admin] && current_user && !current_user.admin?
    path = "#{controller_name}/#{action_name}"

    notes = Note.where(:path=>path)

    if notes.empty? && options[:fixed]
      notes = [Note.create!(:path=>path, :title => options[:default_title])]
    end

    str = notes.map do |note|
      in_place_edit_panel(note, path)
    end.join.html_safe

    str << content_tag(:div, link_to("Add New Note", notes_path(:path=>path), :method=>:post, :remote=>true), :class=>'panel', :id=>"add_#{path.gsub(/\//,'_')}") if allow_admin

    str
  end

  # like local_notes but private?
  def private_notes
    
  end
end


