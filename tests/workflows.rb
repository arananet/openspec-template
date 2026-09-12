require 'yaml'
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
