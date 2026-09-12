require 'yaml'
require 'date'
require 'json'
require 'open3'
require 'digest'
require 'fileutils'
require 'time'

module OpenSpec
  class Error < StandardError; end

  class Project
    REQUIRED = %w[title description acceptance_criteria test_plan status].freeze
    STATUSES = %w[draft review approved].freeze
    TEST_PATTERNS = %w[**/tests/**/* **/test/**/* **/*_test.* **/test_* **/*.test.* **/*.spec.*].freeze
    attr_reader :root, :config

    def initialize(root)
      @root = File.expand_path(root)
      @config = load_yaml('.openspec/config.yaml')
    end

    def load_yaml(path, content = nil)
      content ||= File.read(File.join(root, path))
      tree = Psych.parse_stream(content)
      raise Error, "#{path}: expected one YAML document" unless tree.children.length == 1
      inspect_mapping = lambda do |node|
        if node.is_a?(Psych::Nodes::Mapping)
          keys = node.children.each_slice(2).map do |key, _value|
            raise Error, "#{path}: YAML keys must be scalars" unless key.is_a?(Psych::Nodes::Scalar)
            key.value
          end
          raise Error, "#{path}: duplicate YAML keys" unless keys.uniq == keys
        end
        (node.children || []).each { |child| inspect_mapping.call(child) } if node.respond_to?(:children)
      end
      inspect_mapping.call(tree)
      value = YAML.safe_load(content, permitted_classes: [Date, Time], aliases: false)
      raise Error, "#{path}: expected a YAML mapping" unless value.is_a?(Hash)
      value
    rescue Psych::Exception, Errno::ENOENT => exception
      raise Error, "#{path}: #{exception.message}"
    end

    def setting(*keys, default: nil)
      value = keys.reduce(config) { |parent, key| parent.is_a?(Hash) ? parent[key] : nil }
      value.nil? ? default : value
    end

    def enabled(*keys, default: true)
      value = setting(*keys, default: default)
      raise Error, "#{keys.join('.')}: expected true or false" unless [true, false].include?(value)
      value
    end

    def configured!(template: false)
      raise Error, 'config has unresolved placeholders; finish onboarding or explicitly use --template' if !template && JSON.generate(config).include?('{{')
      minimum = setting('spec', 'min_acceptance_criteria', default: 1)
      raise Error, 'spec.min_acceptance_criteria must be a positive integer' unless minimum.is_a?(Integer) && minimum > 0
      statuses = setting('spec', 'statuses', default: STATUSES)
      raise Error, 'spec.statuses must be a nonempty subset of draft/review/approved' unless statuses.is_a?(Array) && !statuses.empty? && (statuses - STATUSES).empty?
      required = setting('spec', 'required_fields', default: REQUIRED)
      raise Error, 'spec.required_fields must be a list of field names' unless required.is_a?(Array) && required.all? { |field| field.is_a?(String) }
      %w[spec testing ci hooks verification execution].each do |section|
        raise Error, "#{section} must be a mapping" if config.key?(section) && !config[section].is_a?(Hash)
      end
      %w[spec.enforce_on_commit spec.enforce_on_pr spec.approved_required_for_merge testing.require_tests testing.fail_on_missing_tests ci.fail_on_missing_spec ci.fail_on_draft_spec ci.run_tests ci.fail_on_test_failure ci.fail_on_missing_tests hooks.pre_commit.enabled hooks.pre_commit.block_if_no_spec hooks.pre_commit.warn_only hooks.commit_msg.enabled hooks.commit_msg.require_spec_reference execution.enabled].each do |path|
        enabled(*path.split('.')) unless setting(*path.split('.')).nil?
      end
      raise Error, 'testing.coverage_threshold is unsupported; enforce coverage in testing.test_command' unless setting('testing', 'coverage_threshold').nil?
      raise Error, 'ci.notify_slack is unsupported; configure a separate notification workflow' if enabled('ci', 'notify_slack', default: false)
    end

    def meaningful?(value)
      return false unless value.is_a?(String)
      text = value.gsub(/<!--.*?-->/m, '').strip
      !text.empty? && text !~ /\A(?:TODO|TBD|\{\{[^}]+\}\})[.!]?\z/i
    end

    def validate_spec(path, strict: false, approved: false, content: nil)
      spec = load_yaml(path, content)
      (REQUIRED + setting('spec', 'required_fields', default: REQUIRED)).uniq.each do |field|
        raise Error, "#{path}: missing required field: #{field}" unless spec.key?(field)
      end
      status = spec['status']
      raise Error, "#{path}: invalid status #{status.inspect}" unless setting('spec', 'statuses', default: STATUSES).include?(status)
      raise Error, "#{path}: status is 'draft' but implementation readiness is required" if strict && status == 'draft'
      raise Error, "#{path}: approved status required for merge" if approved && status != 'approved'
      %w[title description].each do |field|
        raise Error, "#{path}: #{field} must contain meaningful text" unless meaningful?(spec[field]) || (status == 'draft' && spec[field].is_a?(String) && !spec[field].strip.empty?)
      end
      %w[acceptance_criteria test_plan].each do |field|
        values = spec[field]
        minimum = field == 'acceptance_criteria' ? setting('spec', 'min_acceptance_criteria', default: 1) : 1
        raise Error, "#{path}: #{field} needs at least #{minimum} nonempty text items" unless values.is_a?(Array) && values.length >= minimum && values.all? { |item| meaningful?(item) || (status == 'draft' && item.is_a?(String) && !item.strip.empty?) }
      end
      spec
    end

    def git(*args, allow_failure: false)
      output, error, result = Open3.capture3('git', '-C', root, *args)
      raise Error, "git #{args.first}: #{error.strip}" unless result.success? || allow_failure
      output
    end

    def matches?(path, patterns)
      raise Error, 'path patterns must be an array of strings' unless patterns.is_a?(Array) && patterns.all? { |pattern| pattern.is_a?(String) }
      patterns.any? { |pattern| File.fnmatch?(pattern, path, File::FNM_PATHNAME | File::FNM_DOTMATCH) }
    end

    def test_file?(path)
      return false if path.start_with?('.openspec/')
      matches?(path, setting('testing', 'test_patterns', default: TEST_PATTERNS)) && !path.end_with?('.md')
    end

    def source_file?(path)
      return false if path.start_with?('.openspec/specs/', '.openspec/runs/', 'docs/') || path.end_with?('.md') || test_file?(path)
      matches?(path, setting('spec', 'source_patterns', default: ['**/*']))
    end

    def changed_files(base: nil, staged: false)
      args = staged ? ['diff', '--cached'] : ['diff', "#{base}...HEAD"]
      git(*args, '--name-only', '-z').split("\0")
    end

    def coverage(files, staged: false, ci: false)
      source = files.select { |path| source_file?(path) }
      specs = files.select { |path| path.match?(%r{\A\.openspec/specs/[^/]+\.spec\.yaml\z}) }
      live_specs = specs.select do |path|
        staged ? !git('ls-files', '--stage', '--', path).empty? : File.file?(File.join(root, path))
      end
      enforce = enabled('spec', staged ? 'enforce_on_commit' : 'enforce_on_pr')
      enforce &&= staged ? enabled('hooks', 'pre_commit', 'block_if_no_spec') : enabled('ci', 'fail_on_missing_spec')
      raise Error, 'source changes but no spec changes included' if enforce && !source.empty? && live_specs.empty?
      live_specs.each do |path|
        content = staged ? git('show', ":#{path}") : nil
        validate_spec(path, strict: !source.empty?, approved: ci && enabled('spec', 'approved_required_for_merge', default: false), content: content)
      end
      return if source.empty?
      if ci && enabled('testing', 'require_tests') && enabled('testing', 'fail_on_missing_tests') && enabled('ci', 'fail_on_missing_tests')
        raise Error, 'source changes require test changes in the same PR' unless files.any? { |path| test_file?(path) && File.file?(File.join(root, path)) }
      end
    end

    def check(args)
      options = { strict: false, template: false, ci: false, staged: false, base: nil }
      until args.empty?
        flag = args.shift
        case flag
        when '--strict' then options[:strict] = true
        when '--template' then options[:template] = true
        when '--ci' then options[:ci] = true
        when '--staged' then options[:staged] = true
        when '--base' then options[:base] = args.shift or raise Error, '--base requires a Git ref'
        when '--pr'
          raise Error, '--pr requires a number' unless args.shift.to_s.match?(/\A\d+\z/)
          options[:base] = ENV['GITHUB_BASE_SHA'] || "origin/#{ENV.fetch('GITHUB_BASE_REF', 'main')}"
        else raise Error, "unknown flag: #{flag}"
        end
      end
      configured!(template: options[:template])
      strict = options[:strict] || (options[:ci] && enabled('ci', 'fail_on_draft_spec', default: false))
      paths = Dir.glob(File.join(root, '.openspec/specs/*.spec.yaml')).sort
      paths.each do |path|
        relative = path.delete_prefix(root + '/')
        validate_spec(relative, strict: strict)
        puts "PASS: #{File.basename(path)}"
      end
      if options[:staged] || options[:base]
        coverage(changed_files(base: options[:base], staged: options[:staged]), staged: options[:staged], ci: options[:ci])
      end
      0
    end

    def hook(args)
      kind = args.shift
      return 0 unless enabled('hooks', kind, 'enabled')
      if kind == 'pre_commit'
        return 0 unless enabled('spec', 'enforce_on_commit')
        begin
          coverage(changed_files(staged: true), staged: true)
        rescue Error => exception
          raise unless enabled('hooks', kind, 'warn_only', default: false)
          warn "warning: #{exception.message}"
        end
      elsif kind == 'commit_msg'
        return 0 unless enabled('hooks', kind, 'require_spec_reference', default: false)
        message = File.read(args.fetch(0))
        return 0 if message.match?(/\A(?:Merge|Revert|fixup!|squash!)/)
        pattern = setting('hooks', kind, 'pattern', default: 'spec: <slug>')
        raise Error, 'commit message pattern must contain <slug>' unless pattern.is_a?(String) && pattern.include?('<slug>')
        expression = Regexp.escape(pattern).sub('<slug>', '([a-z0-9]+(?:-[a-z0-9]+)*)')
        match = message.match(Regexp.new(expression, Regexp::IGNORECASE))
        raise Error, 'commit message must include a spec reference' unless match && File.file?(File.join(root, ".openspec/specs/#{match[1]}.spec.yaml"))
      else
        raise Error, "unknown hook: #{kind}"
      end
      0
    end

    def scaffold(args)
      name = nil
      type = 'feature'
      force = false
      until args.empty?
        value = args.shift
        case value
        when '--type' then type = args.shift
        when '--force' then force = true
        else
          raise Error, "unexpected argument: #{value}" if value.start_with?('-') || name
          name = value
        end
      end
      raise Error, 'scaffold requires a name and --type feature|bugfix' unless name && %w[feature bugfix].include?(type)
      slug = name.downcase.gsub(/[^a-z0-9]+/, '-').sub(/\A-/, '').sub(/-\z/, '')
      path = spec_path(slug)
      raise Error, "spec already exists: #{path}" if File.exist?(File.join(root, path)) && !force
      template = ".openspec/templates/#{type}.spec.yaml"
      content = File.read(File.join(root, template)).gsub('{{STATUS}}', JSON.generate('draft'))
      spec = load_yaml(template, content)
      author = git('config', '--get', 'user.name', allow_failure: true).strip
      replacements = { '{{FEATURE_NAME}}' => name, '{{SLUG}}' => slug, '{{STATUS}}' => 'draft',
                       '{{AUTHOR}}' => author, '{{DATE}}' => Date.today.iso8601 }
      replace = lambda do |value|
        case value
        when Hash then value.transform_values { |item| replace.call(item) }
        when Array then value.map { |item| replace.call(item) }
        when String then replacements.reduce(value) { |text, (key, replacement)| text.gsub(key) { replacement } }
        else value
        end
      end
      spec = replace.call(spec)
      %w[implementer reviewer qa product_owner].each do |role|
        value = setting('roles', "default_#{role}")
        spec.fetch('roles', {})[role] = value if meaningful?(value)
      end
      FileUtils.mkdir_p(File.dirname(File.join(root, path)))
      File.write(File.join(root, path), YAML.dump(spec))
      puts "Created #{path}. Fill in the scope, acceptance criteria and tests before setting status: review."
      0
    end

    def ci_tests(args)
      base = nil
      unless args.empty?
        raise Error, 'ci-tests accepts --base <ref>' unless args.shift == '--base' && args.length == 1
        base = args.shift
      end
      configured!
      files = base ? changed_files(base: base) : git('ls-files', '-z').split("\0")
      return 0 unless files.any? { |path| source_file?(path) || test_file?(path) || path.start_with?('.openspec/specs/') }
      paths = files.select { |path| path.match?(%r{\A\.openspec/specs/[^/]+\.spec\.yaml\z}) && File.file?(File.join(root, path)) }
      paths = Dir.glob(File.join(root, '.openspec/specs/*.spec.yaml')).map { |path| path.delete_prefix(root + '/') } if paths.empty?
      paths.select! { |path| %w[review approved].include?(load_yaml(path)['status']) }
      raise Error, 'no implementation-ready spec available for verification' if paths.empty?
      results = paths.map { |path| verify(File.basename(path, '.spec.yaml'), ci: true) }
      results.max
    end
  end

  def self.main(args)
    command = args.shift
    if [nil, '--help', '-h', 'help'].include?(command)
      puts <<~HELP
        OpenSpec (Bash, Git and Ruby standard libraries)
        scripts/openspec scaffold "<name>" [--type feature|bugfix] [--force]
        scripts/openspec check [--strict] [--template] [--ci] [--base <ref> | --pr <number> | --staged]
        scripts/openspec init
        scripts/openspec verify <slug>
        scripts/openspec status [<slug>]
        scripts/openspec pause <slug>
        scripts/openspec resume <slug>
        scripts/openspec run <slug> [--resume]
        scripts/openspec ci-tests [--base <ref>]
      HELP
      return 0
    end
    project = Project.new(ENV.fetch('OPENSPEC_ROOT', File.expand_path('..', __dir__)))
    case command
    when 'check' then project.check(args)
    when 'hook' then project.hook(args)
    when 'scaffold' then project.scaffold(args)
    when 'ci-tests' then project.exclusive { project.ci_tests(args) }
    when 'verify', 'run', 'pause', 'resume'
      slug = args.shift
      project.spec_path(slug)
      resume = command == 'run' && args == ['--resume']
      raise Error, 'unexpected arguments' unless args.empty? || resume
      if command == 'pause'
        project.pause(slug)
      else
        project.exclusive do
          case command
          when 'verify' then project.verify(slug)
          when 'run' then project.run(slug, resume: resume)
          when 'resume'
            FileUtils.rm_f(File.join(project.runtime_dir(slug), 'pause'))
            project.verify(slug)
          end
        end
      end
    when 'status'
      raise Error, 'status accepts at most one slug' if args.length > 1
      project.status(args.shift)
      0
    when 'init'
      raise Error, 'init accepts no arguments' unless args.empty?
      project.configured!
      puts 'OpenSpec is initialized and configured.'
      0
    else raise Error, "unknown command: #{command}"
    end
  rescue Error, ArgumentError, KeyError, SystemCallError, JSON::ParserError => exception
    warn "error: #{exception.message}"
    1
  end
end

require_relative 'openspec_runtime'

exit OpenSpec.main(ARGV) if $PROGRAM_NAME == __FILE__
