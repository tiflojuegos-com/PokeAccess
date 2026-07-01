module PokeAccess
  # Mail is shown by pbDisplayMail as a drawn card overlay (not a message window), so its body and
  # sender never reach the dialogue hook; these read them when the card opens.

  # The spoken text of a mail: its body then "from <sender>", or nil when empty.
  def self.mail_text(mail)
    return nil unless mail
    parts = []
    msg = (mail.message rescue nil)
    parts.push(clean(msg)) if msg && !msg.to_s.strip.empty?
    snd = (mail.sender rescue nil)
    parts.push(I18n.t(:mail_from, :name => snd)) if snd && !snd.to_s.strip.empty?
    parts.empty? ? nil : parts.join(". ")
  end

  # Speaks a mail's body and sender.
  def self.say_mail(mail)
    t = mail_text(mail)
    speak(t, true) if t
  end
end

# pbDisplayMail is a top-level method in both engines; read the mail before its modal card shows.
PokeAccess::Hooks.wrap_global("pbDisplayMail", "hook_mail", :before) { |args, _r| PokeAccess.say_mail(args[0]) }
