require 'yaml'
require 'json'
require 'tmpdir'
require 'fileutils'
require 'open3'

root = File.expand_path('..', __dir__)
workflow = YAML.load_file(File.join(root, '.github/workflows/spec-ai-review.yml'))
steps = workflow.fetch('jobs').fetch('cost-guard').fetch('steps')
config_script = steps.find { |step| step['id'] == 'cfg' }.fetch('run')
guard_script = steps.find { |step| step['id'] == 'guard' }.fetch('run')
guard_script = guard_script.gsub('${{ steps.cfg.outputs.enabled }}', 'false')
guard_script = guard_script.gsub('${{ steps.cfg.outputs.daily_max_runs }}', '50')
guard_script = guard_script.gsub('${{ steps.cfg.outputs.window_hours }}', '24')
raise 'unresolved workflow expression' if guard_script.include?('${{')

Dir.mktmpdir('openspec-workflow') do |sandbox|
  FileUtils.mkdir_p(File.join(sandbox, '.openspec'))
  original = YAML.load_file(File.join(root, '.openspec/config.yaml'))
  raise 'AI review must default off' unless original.fetch('agents').fetch('spec_review').fetch('enabled') == false
  [false, true, nil].each do |setting|
    config = Marshal.load(Marshal.dump(original))
    review = config.fetch('agents').fetch('spec_review')
    setting.nil? ? review.delete('enabled') : review['enabled'] = setting
    File.write(File.join(sandbox, '.openspec/config.yaml'), YAML.dump(config))
    output_file = File.join(sandbox, 'output')
    File.write(output_file, '')
    output, result = Open3.capture2e({'GITHUB_OUTPUT' => output_file}, 'bash', '-c', config_script, chdir: sandbox)
    raise output unless result.success?
    expected = "review_enabled=#{setting == true}"
    raise "wrong config decision: #{expected}" unless File.readlines(output_file).map(&:strip).include?(expected)
    File.write(output_file, '')
    output, result = Open3.capture2e(
      {'GITHUB_OUTPUT' => output_file, 'REVIEW_ENABLED' => (setting == true).to_s},
      'bash', '-c', guard_script, chdir: sandbox
    )
    raise output unless result.success?
    raise 'wrong guard decision' unless File.read(output_file).strip == "proceed=#{setting == true}"
  end
end
puts 'PASS: workflow opt-in, opt-out, missing setting, and disabled cost guard'

Dir.glob(File.join(root, '.github/workflows/*.yml')).each { |path| YAML.load_file(path) }
puts 'PASS: workflow YAML parses'

lint_workflow = YAML.load_file(File.join(root, '.github/workflows/lint.yml'))
markdown_steps = lint_workflow.fetch('jobs').fetch('markdownlint').fetch('steps')
raise 'CI must use the shared lint target' unless markdown_steps.any? { |step| step['run'] == 'make lint-markdown' }
raise 'CI must install locked dependencies' unless markdown_steps.any? { |step| step['run'] == 'make setup-lint' }
node_step = markdown_steps.find { |step| step.fetch('uses', '').start_with?('actions/setup-node@') }
raise 'CI Markdown lint must use Node 24' unless node_step.fetch('with').fetch('node-version') == '24'
manifest = JSON.parse(File.read(File.join(root, 'tools/lint/package.json')))
raise 'Markdown CLI version must stay pinned' unless manifest.fetch('devDependencies').fetch('markdownlint-cli2') == '0.23.2'
rules = JSON.parse(File.read(File.join(root, '.markdownlint-cli2.jsonc'))).fetch('config')
expected_rules = {
  'default' => true, 'MD013' => false, 'MD033' => false, 'MD041' => false,
  'MD024' => { 'siblings_only' => true }
}
raise 'markdownlint rules changed' unless rules == expected_rules
puts 'PASS: CI uses shared Markdown targets, a pinned CLI and the existing rules'

Dir.mktmpdir('openspec lint runner ') do |sandbox|
  FileUtils.mkdir_p(File.join(sandbox, 'scripts'))
  FileUtils.cp(File.join(root, 'scripts/lint-markdown'), File.join(sandbox, 'scripts/lint-markdown'))
  bin = File.join(sandbox, 'bin')
  FileUtils.mkdir_p(bin)
  FileUtils.ln_s('/usr/bin/dirname', File.join(bin, 'dirname'))
  run_lint = lambda do |extra = {}|
    Open3.capture2e({'PATH' => bin, 'FAKE_NODE_EXIT' => '0', 'FAKE_LINT_EXIT' => '0'}.merge(extra),
                   '/bin/bash', File.join(sandbox, 'scripts/lint-markdown'), chdir: '/')
  end
  output, result = run_lint.call
  raise 'missing Node must fail with guidance' unless result.exitstatus == 2 && output.include?('Node.js 22')
  File.write(File.join(bin, 'node'), "#!/bin/bash\nexit \"${FAKE_NODE_EXIT:-0}\"\n")
  FileUtils.chmod(0755, File.join(bin, 'node'))
  output, result = run_lint.call
  raise 'missing dependencies must fail with guidance' unless result.exitstatus == 2 && output.include?('make setup-lint')
  linter = File.join(sandbox, 'tools/lint/node_modules/.bin/markdownlint-cli2')
  FileUtils.mkdir_p(File.dirname(linter))
  File.write(linter, "#!/bin/bash\nprintf '%s\\n' \"$PWD\" \"$@\"\nexit \"${FAKE_LINT_EXIT:-0}\"\n")
  FileUtils.chmod(0755, linter)
  output, result = run_lint.call
  expected = [sandbox, '--config', '.markdownlint-cli2.jsonc', '**/*.md', '!**/node_modules/**', '!**/CHANGELOG.md']
  raise 'lint runner changed arguments or cwd' unless result.success? && output.lines.map(&:strip) == expected
  _output, result = run_lint.call('FAKE_LINT_EXIT' => '1')
  raise 'lint failures must propagate' unless result.exitstatus == 1
  _output, result = run_lint.call('FAKE_NODE_EXIT' => '2')
  raise 'unsupported Node must fail' unless result.exitstatus == 2
end
puts 'PASS: lint runner prerequisites, paths with spaces, CI globs and failure propagation'
