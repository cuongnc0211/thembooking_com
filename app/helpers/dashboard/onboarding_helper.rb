module Dashboard::OnboardingHelper
  def step_description(step)
    case step
    when 1 then "Tell us a bit about yourself"
    when 2 then "Set up your business profile"
    when 3 then "When are you open for business?"
    when 4 then "Add at least one service to get started"
    end
  end

  def step_name(step)
    case step
    when 1 then "Your Information"
    when 2 then "Business Details"
    when 3 then "Operating Hours"
    when 4 then "Services"
    end
  end

  def step_circle_class(is_completed, is_current)
    base = "w-10 h-10 rounded-full flex items-center justify-center text-sm font-semibold transition-colors"
    if is_completed
      "#{base} bg-primary-500 text-white"
    elsif is_current
      "#{base} bg-primary-100 text-primary-600 border-2 border-primary-500"
    else
      "#{base} bg-slate-100 text-slate-400"
    end
  end
end