module AdminHelper
  # Renders breadcrumb items into the :breadcrumbs content_for block.
  # Usage in views: admin_breadcrumbs("Users") or admin_breadcrumbs(link_to("Users", ...), "Edit")
  def admin_breadcrumbs(*crumbs)
    content_for :breadcrumbs do
      items = [ link_to("Admin", admin_root_path, class: "hover:text-gray-700 transition-colors") ]

      crumbs.each_with_index do |crumb, i|
        items << content_tag(:span, " / ", class: "mx-1 text-gray-300")

        if i == crumbs.length - 1
          # Last crumb is plain text (current page)
          items << content_tag(:span, crumb, class: "text-gray-700 font-medium")
        else
          items << crumb
        end
      end

      safe_join(items)
    end
  end
end
