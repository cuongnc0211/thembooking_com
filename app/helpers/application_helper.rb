module ApplicationHelper
  def flash_class(level)
    case level.to_sym
    when :notice then "bg-green-50 border-green-200 text-green-700"
    when :alert then "bg-red-50 border-red-200 text-red-700"
    when :warning then "bg-yellow-50 border-yellow-200 text-yellow-700"
    else "bg-blue-50 border-blue-200 text-blue-700"
    end
  end

  def user_avatar(user, size: 40)
    if user.avatar.attached?
      image_tag user.avatar.variant(resize_to_limit: [ size, size ]).url,
                class: "rounded-full object-cover",
                style: "width: #{size}px; height: #{size}px;"
    else
      content_tag :div,
                  user.name&.first&.upcase || "?",
                  class: "rounded-full bg-gray-300 flex items-center justify-center text-gray-600 font-semibold",
                  style: "width: #{size}px; height: #{size}px; font-size: #{size/2}px;"
    end
  end
end
