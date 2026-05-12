#!/usr/bin/env ruby
# frozen_string_literal: true

# Static analysis for IDOR baseline (Task 2 — maio/2026).
#
# Walks every controller under app/controllers/{api,open_api/v1} and reports:
#   - Whether the controller requires authentication globally
#   - For each action: does it call `authorize` and/or `policy_scope`
#   - Whether a corresponding Pundit policy file exists
#
# This is static — it does not boot Rails. The output is a markdown table that
# becomes the Phase 0 baseline artifact.
#
# Usage:
#   ruby doc/security/audit_idor_baseline.rb > doc/security/inventory_$(date +%Y-%m-%d).md

require 'pathname'

ROOT = Pathname.new(File.expand_path('../..', __dir__))
CONTROLLER_DIRS = [
  ROOT.join('app/controllers/api'),
  ROOT.join('app/controllers/open_api/v1')
].freeze
POLICY_DIR = ROOT.join('app/policies')

# Parse a controller file and return a structured summary.
def analyze_controller(path)
  src = path.read
  rel = path.relative_path_from(ROOT).to_s

  class_match = src.match(/class\s+([A-Za-z0-9:_]+)/)
  class_name = class_match ? class_match[1] : '?'

  # Authentication baseline: scan for before_action / skip_before_action involving authenticate_user!
  auth_directives = src.lines
                       .map(&:strip)
                       .select { |l| l =~ /^(before_action|skip_before_action)\s+:authenticate_user!\b/ }
  auth_summary =
    if auth_directives.empty?
      '⚠️ none'
    else
      auth_directives.map { |l| "`#{l}`" }.join('<br>')
    end

  # Find public action methods. Treat everything up to `private` (or `protected`) as public.
  public_part = src.split(/^\s*(?:private|protected)\b/).first
  methods = public_part.to_s.scan(/^\s*def\s+([a-zA-Z_][a-zA-Z0-9_?!]*)/).flatten

  # For each method, capture its body and look for authorize / policy_scope
  bodies = {}
  methods.each do |m|
    if (md = src.match(/^\s*def\s+#{Regexp.escape(m)}\b(.*?)^\s*end\b/m))
      bodies[m] = md[1]
    end
  end

  action_rows = methods.map do |m|
    body = bodies[m] || ''
    has_authorize = body =~ /\bauthorize\b/
    has_scope = body =~ /\bpolicy_scope\b/
    {
      action: m,
      authorize: !has_authorize.nil?,
      policy_scope: !has_scope.nil?
    }
  end

  {
    file: rel,
    class_name: class_name,
    auth: auth_summary,
    actions: action_rows
  }
end

def policy_files
  @policy_files ||= POLICY_DIR.glob('**/*.rb').map { |f| f.basename('.rb').to_s }
end

def render(reports)
  puts '# Inventário IDOR — baseline'
  puts
  puts "_Gerado por `doc/security/audit_idor_baseline.rb` em #{Time.now.strftime('%Y-%m-%d %H:%M')}._"
  puts
  puts 'Legenda das colunas por action:'
  puts '- **authorize**: action chama `authorize` (Pundit) — `✓` sim, `✗` não'
  puts '- **scope**: action chama `policy_scope` (filtra coleção) — `✓` sim, `—` n/a (não-coleção)'
  puts '- **risco**: heurística — `🔴` action é `show/update/destroy` sem `authorize`; `🟡` coleção sem `policy_scope`; `🟢` parece coberto'
  puts
  puts '> ⚠️ Análise estática. Não considera herança de filtros via includes/concerns. Casos suspeitos pedem verificação manual.'
  puts

  total_actions = 0
  total_unauthorized = 0
  total_unscoped_collections = 0

  reports.each do |report|
    puts "## `#{report[:file]}`"
    puts
    puts "**Classe:** `#{report[:class_name]}`  "
    puts "**Auth baseline:** #{report[:auth]}"
    puts
    puts '| Action | authorize | scope | risco |'
    puts '|--------|-----------|-------|-------|'
    report[:actions].each do |a|
      total_actions += 1
      name = a[:action]
      coll_like = %w[index list search].include?(name)
      member_like = %w[show update destroy create].include?(name) || name.start_with?('show_') || name.end_with?('?')
      risk =
        if member_like && !a[:authorize]
          total_unauthorized += 1
          '🔴'
        elsif coll_like && !a[:policy_scope] && !a[:authorize]
          total_unscoped_collections += 1
          '🟡'
        elsif a[:authorize] || a[:policy_scope]
          '🟢'
        else
          '🟡'
        end
      auth = a[:authorize] ? '✓' : '✗'
      scope = a[:policy_scope] ? '✓' : (coll_like ? '✗' : '—')
      puts "| `#{name}` | #{auth} | #{scope} | #{risk} |"
    end
    puts
  end

  puts '## Resumo'
  puts
  puts "- Controllers analisados: **#{reports.size}**"
  puts "- Actions totais (públicas): **#{total_actions}**"
  puts "- Actions `show/update/destroy/create` sem `authorize`: **#{total_unauthorized}** 🔴"
  puts "- Coleções (`index/list/search`) sem `policy_scope` nem `authorize`: **#{total_unscoped_collections}** 🟡"
end

# Analyze a single policy file: look for predicate methods (e.g. show?) and
# flag the ones whose body never references ownership (`user.id == record.id`,
# `record.author`, etc.) and never restricts to admin/manager. These are the
# policies most likely to be over-permissive — i.e. the class of bug found in
# `UserPolicy#show?` (the IDOR confirmed by Claupper).
SELF_REGEX = /
  user\.id\s*==\s*record\.id |          # user.id == record.id
  record\.id\s*==\s*user\.id |          # record.id == user.id
  record\.\w+(?:\.\w+)*\.user_id\s*==\s*user\.id |  # record.x.user_id == user.id
  record\.user_id\s*==\s*user\.id |     # record.user_id == user.id
  user\.id\s*==\s*record\.user_id |     # user.id == record.user_id (rare)
  record\.user\s*==\s*user |            # record.user == user
  record\.\w+\.user_id\s*==\s*user&?\.statistic_profile&?\.id |  # record.x.user_id == user.statistic_profile.id
  record&?\.statistic_profile_id\s*==\s*user&?\.statistic_profile&?\.id
/x.freeze

ROLE_REGEX = /
  user&?\.(admin\?|manager\?|privileged\?) |   # user.admin?, user&.admin?
  user\.has_role\?\s+:(admin|manager)          # user.has_role? :admin
/x.freeze

def analyze_policy(path)
  src = path.read
  rel = path.relative_path_from(ROOT).to_s
  class_name = (src.match(/class\s+([A-Za-z0-9:_]+)/) || [])[1] || '?'

  # First pass: gather every predicate body
  bodies = {}
  src.scan(/^\s*def\s+([a-z_]+\?)(.*?)^\s*end\b/m).each do |name, body|
    bodies[name] = body
  end

  rows = bodies.map do |name, body|
    body_trim = body.strip

    # Aliasing: body is just `other_predicate?` — chase the reference (one level deep)
    aliased = nil
    if body_trim =~ /\A([a-z_]+\?)\z/
      aliased = Regexp.last_match(1)
    end
    effective_body = aliased && bodies[aliased] ? bodies[aliased] : body

    references_self = effective_body =~ SELF_REGEX
    references_role = effective_body =~ ROLE_REGEX
    returns_true_literal = effective_body.strip == 'true'
    body_first_line = body.strip.lines.first.to_s.strip[0, 80]

    risk =
      if returns_true_literal
        '🔴 retorna `true`'
      elsif references_self && references_role
        '🟢 valida posse + role'
      elsif references_role && !references_self
        '🟡 só role'
      elsif references_self && !references_role
        '🟡 só posse'
      else
        '🔴 nenhuma checagem clara'
      end

    note = aliased ? " (alias de `#{aliased}`)" : ''

    # Detect permissive disjunction: many `||` clauses in show?/index?/update?
    # is the pattern of UserPolicy#show? — multiple OR branches mean any one
    # can grant access. Each branch needs to be safe.
    or_count = effective_body.scan('||').size
    permissive_or =
      or_count >= 2 &&
      %w[show? index? update? destroy? create?].include?(name) &&
      risk.start_with?('🟢') # only worth flagging when other checks pass

    flag = permissive_or ? '🔵 revisar cláusulas OR' : risk

    { method: name, risk: flag, first_line: body_first_line + note, or_count: or_count }
  end

  { file: rel, class_name: class_name, methods: rows }
end

def render_policies(policies)
  puts
  puts '---'
  puts
  puts '# Análise de policies'
  puts
  puts 'Heurística: o `UserPolicy#show?` (vetor confirmado por Claupper) libera leitura quando `record.is_allow_contact && record.member?` é verdadeiro — não checa posse nem role admin/manager. Esta seção procura padrões similares.'
  puts
  puts 'Sinais:'
  puts '- `🟢 valida posse + role`: corpo referencia `user.id == record.id` (ou equivalente) E também `user.admin?`/`user.manager?`/`user.privileged?`'
  puts '- `🟡 só role`: só checagem de role (suficiente para recursos administrativos puros)'
  puts '- `🟡 só posse`: só checagem de posse (suficiente para "current user resources")'
  puts '- `🔴 nenhuma checagem clara` ou `retorna true`: corpo não referencia nem posse nem role — candidato a IDOR'
  puts '- `🔵 revisar cláusulas OR`: 🟢 estruturalmente mas com 2+ `||` em `show?`/`update?`/etc. — qualquer cláusula adicional pode bypassar (é o padrão do `UserPolicy#show?`)'
  puts
  puts '> ⚠️ Heurística simples. Resultado 🔴 não é prova de vulnerabilidade — pode haver lógica equivalente expressa de outro jeito. Mas todo 🔴 merece revisão manual.'
  puts

  red_count = 0
  blue_count = 0
  policies.each do |p|
    next if p[:methods].empty?

    puts "## `#{p[:file]}`"
    puts
    puts '| Predicate | Risco | Primeira linha |'
    puts '|-----------|-------|----------------|'
    p[:methods].each do |m|
      red_count += 1 if m[:risk].start_with?('🔴')
      blue_count += 1 if m[:risk].start_with?('🔵')
      puts "| `#{m[:method]}` | #{m[:risk]} | `#{m[:first_line]}` |"
    end
    puts
  end

  puts '## Resumo de policies'
  puts
  puts "- Policies analisadas: **#{policies.size}**"
  puts "- Predicates 🔴 (sem checagem clara de posse nem role): **#{red_count}**"
  puts "- Predicates 🔵 (estruturalmente ok mas com cláusulas OR a revisar manualmente): **#{blue_count}**"
end

reports = CONTROLLER_DIRS
          .flat_map { |dir| dir.glob('*.rb').sort }
          .map { |f| analyze_controller(f) }

policies = POLICY_DIR.glob('**/*.rb').sort.map { |f| analyze_policy(f) }

render(reports)
render_policies(policies)
