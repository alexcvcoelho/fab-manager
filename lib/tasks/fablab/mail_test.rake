# lib/tasks/test_smtp_email.rake

namespace :fablab do
    desc 'Envia um email de teste via SMTP e exibe todos os logs possíveis'
    task email_test: :environment do
      begin
        notif = Notification.find_by(notification_type_id: NotificationType.find_by(name: 'notify_user_auth_migration'))
        notif.receiver.email = "alex.coelho@bluecore.com.br"
        NotificationsMailer.send_mail_by(notif)
        puts "Enviado com sucesso"
      rescue => e
        # Registra erros no console
        puts "Erro ao enviar email via SMTP: #{e.message}"
      end
    end
  end
  