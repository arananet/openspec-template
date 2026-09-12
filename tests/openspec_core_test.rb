require 'minitest/autorun'
require 'tmpdir'
require_relative '../scripts/openspec_core'

class OpenSpecCoreTest < Minitest::Test
  def setup
    @root = Dir.mktmpdir('openspec-core-')
    FileUtils.mkdir_p(File.join(@root, '.openspec/specs'))
    @config = { 'project' => { 'name' => 'fixture' } }
    write_config
    @spec = { 'title' => 'Fixture', 'description' => 'Verify a deterministic contract.', 'status' => 'review',
              'acceptance_criteria' => ['The check rejects invalid input.'], 'test_plan' => ['Run the regression suite.'] }
    write_spec
    Open3.capture3('git', 'init', '-q', @root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def write(path, content)
    target = File.join(@root, path)
    FileUtils.mkdir_p(File.dirname(target))
    File.write(target, content)
  end

  def write_config
    write('.openspec/config.yaml', YAML.dump(@config))
  end

  def write_spec
    write('.openspec/specs/fixture.spec.yaml', YAML.dump(@spec))
  end

  def project
    OpenSpec::Project.new(@root)
  end

  def test_yaml_comments_quotes_lists_and_meaningful_fields
    write('.openspec/specs/fixture.spec.yaml', YAML.dump(@spec).sub('status: review', 'status: "review" # ready'))
    assert_equal 'review', project.validate_spec('.openspec/specs/fixture.spec.yaml')['status']
    %w[description acceptance_criteria test_plan].each do |field|
      original = @spec[field]
      @spec[field] = field == 'description' ? '  ' : ['<!-- fill this -->']
      write_spec
      assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
      @spec[field] = original
    end
    write('.openspec/specs/fixture.spec.yaml', YAML.dump(@spec) + "status: approved\n")
    assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
  end

  def test_config_readiness_and_minimum
    @config['project']['name'] = '{{PROJECT_NAME}}'
    write_config
    assert_raises(OpenSpec::Error) { project.configured! }
    project.configured!(template: true)
    @config['spec'] = { 'min_acceptance_criteria' => 2 }
    write_config
    assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
  end

  def test_coverage_includes_shell_infrastructure_and_extensionless_files
    %w[scripts/tool hooks/pre-commit app.sh infra/main.bicep .github/workflows/test.yml].each do |path|
      assert project.source_file?(path), path
      assert_raises(OpenSpec::Error) { project.coverage([path]) }
    end
    refute project.source_file?('README.md')
    assert project.test_file?('tests/fixture.sh')
    assert project.test_file?('tests/unit/fixture.sh')
    assert project.test_file?('packages/service/tests/unit/fixture.sh')
    refute project.test_file?('.openspec/specs/fixture.spec.yaml')
    assert_raises(OpenSpec::Error) { project.coverage(['app.sh', '.openspec/specs/fixture.spec.yaml'], ci: true) }
    write('tests/fixture.sh', 'true')
    project.coverage(['app.sh', '.openspec/specs/fixture.spec.yaml', 'tests/fixture.sh'], ci: true)
  end

  def test_hooks_use_staged_specs_and_honor_disabled_and_warn_only
    write('app.sh', 'true')
    project.git('add', 'app.sh')
    assert_raises(OpenSpec::Error) { project.hook(['pre_commit']) }
    @config['hooks'] = { 'pre_commit' => { 'warn_only' => true } }
    write_config
    assert_equal 0, project.hook(['pre_commit'])
    @config['hooks']['pre_commit'] = { 'enabled' => false }
    write_config
    assert_equal 0, project.hook(['pre_commit'])
    @config['hooks']['pre_commit'] = { 'enabled' => true }
    write_config
    project.git('add', '.openspec/specs/fixture.spec.yaml')
    @spec['status'] = 'draft'
    write_spec
    assert_equal 0, project.hook(['pre_commit'])
    project.git('add', '.openspec/specs/fixture.spec.yaml')
    assert_raises(OpenSpec::Error) { project.hook(['pre_commit']) }
  end

  def prepare_verification(command = 'bash tests/check.sh')
    write('tests/check.sh', 'exit 0')
    @config['testing'] = { 'test_command' => command }
    write_config
  end

  def test_verify_pass_fail_unverified_and_stale
    prepare_verification
    assert_equal 0, project.verify('fixture')
    assert_equal 'passed', project.status('fixture')['result']
    write('app.sh', 'true')
    assert project.status('fixture')['stale']
    assert_equal 'unverified', project.status('fixture')['result']
    write('tests/check.sh', 'exit 3')
    assert_equal 1, project.verify('fixture')
    assert_equal 'failed', project.read_state('fixture')['result']
    @config['testing']['test_command'] = ''
    write_config
    assert_equal 2, project.verify('fixture')
    assert_equal 'unverified', project.read_state('fixture')['result']
  end

  def test_verify_timeout_changed_inputs_missing_tests_and_ci_policy
    prepare_verification('while :; do :; done')
    assert_equal 2, project.verify('fixture', timeout: 0.1)
    assert_equal 'timeout', project.read_state('fixture')['blocker']
    prepare_verification('printf changed > app.sh')
    assert_equal 2, project.verify('fixture')
    assert_match(/inputs changed/, project.read_state('fixture')['blocker'])
    File.delete(File.join(@root, 'tests/check.sh'))
    assert_equal 2, project.verify('fixture')
    prepare_verification('exit 1')
    @config['ci'] = { 'fail_on_test_failure' => false }
    write_config
    assert_equal 0, project.verify('fixture', ci: true)
    assert_equal 'failed', project.read_state('fixture')['result']
    assert_equal 1, project.verify('fixture')
    @config['ci']['run_tests'] = false
    write_config
    assert_equal 0, project.verify('fixture', ci: true)
    assert_equal 'unverified', project.read_state('fixture')['result']
  end

  def prepare_run(command = 'true')
    prepare_verification
    @config['execution'] = { 'enabled' => true, 'adapter' => 'fake', 'max_attempts' => 2, 'max_seconds' => 5,
                             'max_cost' => 2, 'adapters' => { 'fake' => { 'command' => command, 'max_cost_per_attempt' => 1 } } }
    write_config
  end

  def test_optional_runner_and_completed_resume
    prepare_run
    @config['execution']['enabled'] = false
    write_config
    assert_raises(OpenSpec::Error) { project.run('fixture') }
    @config['execution']['enabled'] = true
    write_config
    assert_equal 0, project.run('fixture')
    assert_equal 1, project.read_state('fixture')['attempts']
    assert_equal 0, project.run('fixture', resume: true)
    assert_equal 1, project.read_state('fixture')['attempts']
    project.pause('fixture')
    assert_equal 'paused', project.status('fixture')['phase']
    assert_equal 2, project.verify('fixture')
    assert_equal 0, project.run('fixture', resume: true)
  end

  def test_runner_budget_and_attempt_limits_persist
    prepare_run
    write('tests/check.sh', 'exit 1')
    @config['execution']['max_cost'] = 1
    write_config
    assert_equal 2, project.run('fixture')
    assert_equal 'reserved cost limit reached', project.read_state('fixture')['blocker']
    assert_equal 1, project.read_state('fixture')['attempts']
    assert_equal 2, project.run('fixture', resume: true)
    @config['execution']['max_cost'] = 3
    write_config
    assert_equal 2, project.run('fixture', resume: true)
    assert_equal 'attempt limit reached', project.read_state('fixture')['blocker']
  end

  def test_runner_pause_and_contract_mutation
    prepare_run('touch .openspec/runs/fixture/pause; while :; do :; done')
    assert_equal 2, project.run('fixture')
    assert_equal 'paused', project.read_state('fixture')['phase']
    prepare_run('printf "status: approved\n" >> .openspec/specs/fixture.spec.yaml')
    assert_equal 2, project.run('fixture', resume: true)
    assert_match(/human review/, project.read_state('fixture')['blocker'])
  end

  def test_policy_flags_and_spec_only_approval
    write('app.sh', 'true')
    @config['spec'] = { 'enforce_on_pr' => false }
    @config['ci'] = { 'fail_on_missing_tests' => false }
    write_config
    project.coverage(['app.sh'], ci: true)
    @config['spec']['approved_required_for_merge'] = true
    write_config
    assert_raises(OpenSpec::Error) { project.coverage(['.openspec/specs/fixture.spec.yaml'], ci: true) }
    @spec['status'] = 'approved'
    write_spec
    project.coverage(['.openspec/specs/fixture.spec.yaml'], ci: true)
    @config['ci']['run_tests'] = 'false'
    write_config
    assert_raises(OpenSpec::Error) { project.configured! }
    @config['ci'] = { 'fail_on_draft_spec' => true }
    @spec['status'] = 'draft'
    write_spec
    write_config
    assert_raises(OpenSpec::Error) { project.check(['--ci']) }
    assert_raises(OpenSpec::Error) { project.changed_files(base: 'missing-ref') }
  end

  def test_commit_message_custom_pattern_and_disable
    @config['hooks'] = { 'commit_msg' => { 'require_spec_reference' => true, 'pattern' => 'Spec(<slug>)' } }
    write_config
    write('message', 'feat: change Spec(fixture)')
    assert_equal 0, project.hook(['commit_msg', File.join(@root, 'message')])
    write('message', 'feat: change Spec(missing)')
    assert_raises(OpenSpec::Error) { project.hook(['commit_msg', File.join(@root, 'message')]) }
    @config['hooks']['commit_msg']['enabled'] = false
    write_config
    assert_equal 0, project.hook(['commit_msg', File.join(@root, 'message')])
  end

  def test_runner_timeout_and_deleted_contract
    prepare_run('while :; do :; done')
    @config['execution']['max_seconds'] = 0.1
    write_config
    assert_equal 2, project.run('fixture')
    assert_equal 'timeout', project.read_state('fixture')['blocker']
    prepare_run('rm .openspec/specs/fixture.spec.yaml')
    assert_equal 2, project.run('fixture', resume: true)
    assert_match(/human review/, project.read_state('fixture')['blocker'])
  end

  def test_workflow_executes_shared_commands_and_fails_closed
    prepare_verification
    FileUtils.cp_r(File.expand_path('../scripts', __dir__), @root)
    project.git('add', '.')
    project.git('-c', 'user.name=Test', '-c', 'user.email=test@example.com', 'commit', '-qm', 'fixture')
    workflow = YAML.load_file(File.expand_path('../.github/workflows/spec-check.yml', __dir__))
    scripts = workflow['jobs'].values.flat_map { |job| job['steps'] }.select { |step| step['name'].include?('shared CLI') }.map { |step| step.fetch('run') }
    assert_equal 2, scripts.length
    scripts.each do |script|
      output, error, result = Open3.capture3({ 'BASE_SHA' => '', 'TEMPLATE_REPOSITORY' => '' }, 'bash', '-e', '-c', script, chdir: @root)
      assert result.success?, output + error
    end
    assert_equal 'passed', project.read_state('fixture')['result']
    @config['project']['name'] = '{{PROJECT_NAME}}'
    write_config
    write('.openspec/template', 'untrusted PR addition')
    scripts.each do |script|
      _output, _error, result = Open3.capture3({ 'BASE_SHA' => 'HEAD', 'TEMPLATE_REPOSITORY' => '' }, 'bash', '-e', '-c', script, chdir: @root)
      refute result.success?
    end
  end

  def test_yaml_documents_required_fields_and_unsupported_settings
    write('.openspec/specs/fixture.spec.yaml', YAML.dump(@spec) + "---\nstatus: approved\n")
    assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
    write_spec
    @config['spec'] = { 'required_fields' => ['owner'] }
    write_config
    assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
    @config['spec'] = { 'statuses' => ['approved'] }
    write_config
    assert_raises(OpenSpec::Error) { project.validate_spec('.openspec/specs/fixture.spec.yaml') }
    @config['testing'] = { 'coverage_threshold' => 80 }
    write_config
    assert_raises(OpenSpec::Error) { project.configured! }
    @config.delete('testing')
    @config['ci'] = { 'notify_slack' => true }
    write_config
    assert_raises(OpenSpec::Error) { project.configured! }
  end

  def test_missing_spec_and_test_policy_switches
    write('app.sh', 'true')
    %w[testing.require_tests testing.fail_on_missing_tests ci.fail_on_missing_tests].each do |path|
      @config = { 'testing' => {}, 'ci' => {} }
      section, key = path.split('.')
      @config[section][key] = false
      write_config
      project.coverage(['app.sh', '.openspec/specs/fixture.spec.yaml'], ci: true)
    end
    @config = { 'ci' => { 'fail_on_missing_spec' => false, 'fail_on_missing_tests' => false } }
    write_config
    project.coverage(['app.sh'], ci: true)
    @config = { 'hooks' => { 'pre_commit' => { 'block_if_no_spec' => false } } }
    write_config
    project.git('add', 'app.sh')
    assert_equal 0, project.hook(['pre_commit'])
    @config = { 'spec' => { 'enforce_on_commit' => false } }
    write_config
    assert_equal 0, project.hook(['pre_commit'])
    @config = {}
    write_config
    File.delete(File.join(@root, '.openspec/specs/fixture.spec.yaml'))
    assert_raises(OpenSpec::Error) { project.coverage(['app.sh', '.openspec/specs/fixture.spec.yaml']) }
  end
end
