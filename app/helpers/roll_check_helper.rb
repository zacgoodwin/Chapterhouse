# frozen_string_literal: true

module RollCheckHelper
  def dnd_roll_result_message(result)
    case result[:status]
    when :crit_success then I18n.t('services.bot_context.representers.check.dnd.crit_success')
    when :crit_failure then I18n.t('services.bot_context.representers.check.dnd.crit_failure')
    else I18n.t('services.bot_context.representers.check.dnd.success', result: result[:total])
    end
  end
end
