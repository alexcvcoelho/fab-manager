# lib/tasks/clean_cpf.rake

namespace :fablab do
    desc "Limpa o campo CPF em todos os perfis"
    task clean_cpf: :environment do |_task, _args|
      profiles = Profile.all
  
      profiles.each do |profile|
        clean_and_pad_cpf(profile)
      end
  
      puts "Limpeza concluída em #{profiles.count} perfis."
    end
  
    def clean_and_pad_cpf(profile)
      if profile.cpf.present?
        cleaned_cpf = profile.cpf.gsub(/\D/, '') # Remove caracteres não numéricos
        padded_cpf = cleaned_cpf.rjust(11, '0')  # Completa com zeros à esquerda
        profile.update(cpf: padded_cpf)
      end
    end
  end
  