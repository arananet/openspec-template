module OpenSpec
  class Project
    def spec_path(slug)
      raise Error, 'expected a lowercase spec slug' unless slug.to_s.match?(/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/)
      ".openspec/specs/#{slug}.spec.yaml"
    end

    def runtime_dir(slug = nil)
      spec_path(slug) if slug
      File.join(root, '.openspec', 'runs', *[slug].compact)
    end

    def atomic_json(path, value)
      FileUtils.mkdir_p(File.dirname(path), mode: 0700)
      temporary = "#{path}.#{Process.pid}.tmp"
      File.open(temporary, 'w', 0600) { |file| file.write(JSON.pretty_generate(value) + "\n") }
      File.rename(temporary, path)
    ensure
      File.delete(temporary) if temporary && File.exist?(temporary)
    end

    def read_state(slug)
      path = File.join(runtime_dir(slug), 'state.json')
      File.exist?(path) ? JSON.parse(File.read(path)) : { 'slug' => slug, 'result' => 'unverified', 'next_step' => 'verify', 'attempts' => 0, 'reserved_cost' => 0, 'elapsed_seconds' => 0 }
    rescue JSON::ParserError => exception
      raise Error, "invalid execution state: #{exception.message}"
    end

    def save_state(slug, state)
      state['updated_at'] = Time.now.utc.iso8601
      atomic_json(File.join(runtime_dir(slug), 'state.json'), state)
      atomic_json(File.join(runtime_dir, 'active.json'), { 'slug' => slug })
      state
    end

    def exclusive
      FileUtils.mkdir_p(runtime_dir, mode: 0700)
      File.open(File.join(runtime_dir, 'lock'), File::RDWR | File::CREAT, 0600) do |lock|
        raise Error, 'another OpenSpec verification or run is active' unless lock.flock(File::LOCK_EX | File::LOCK_NB)
        yield
      ensure
        lock.flock(File::LOCK_UN) if lock
      end
    end

    def fingerprint
      files = git('ls-files', '--cached', '--others', '--exclude-standard', '-z').split("\0").uniq.sort
      digest = Digest::SHA256.new
      digest << git('rev-parse', '--verify', 'HEAD', allow_failure: true)
      git('ls-files', '--stage', '-z').split("\0").each do |entry|
        digest << entry unless entry.split("\t", 2).last.start_with?('.openspec/runs/')
      end
      files.reject { |path| path.start_with?('.openspec/runs/') }.each do |path|
        absolute = File.join(root, path)
        digest << path << "\0"
        if File.symlink?(absolute)
          digest << 'link:' << File.readlink(absolute)
        elsif File.file?(absolute)
          digest << File.stat(absolute).mode.to_s << Digest::SHA256.file(absolute).hexdigest
        else
          digest << 'absent'
        end
      end
      digest.hexdigest
    end

    def positive_number(value, label)
      raise Error, "#{label} must be a finite positive number" unless value.is_a?(Numeric) && value.finite? && value > 0
      value
    end

    def paused?(slug)
      File.exist?(File.join(runtime_dir(slug), 'pause'))
    end

    def process_command(command, log, timeout, slug)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      FileUtils.mkdir_p(File.dirname(log), mode: 0700)
      outcome = nil
      result = nil
      File.open(log, 'w', 0600) do |output|
        process = Process.spawn({ 'OPENSPEC_SPEC' => spec_path(slug), 'OPENSPEC_ROOT' => root }, 'bash', '-c', command,
                                chdir: root, in: File::NULL, out: output, err: output, pgroup: true)
        waiter = Thread.new { Process.waitpid2(process).last }
        until waiter.join(0.05)
          outcome = 'paused' if paused?(slug)
          outcome ||= 'timeout' if Process.clock_gettime(Process::CLOCK_MONOTONIC) - started >= timeout
          break if outcome
        end
        result = waiter.value unless outcome
      ensure
        begin
          Process.kill('KILL', -process) if process
        rescue Errno::ESRCH
          nil
        end
        waiter.join if waiter
      end
      { 'exit_code' => result && result.exitstatus, 'signal' => result && result.termsig,
        'termination' => outcome, 'duration_seconds' => Process.clock_gettime(Process::CLOCK_MONOTONIC) - started }
    end

    def verify(slug, ci: false, timeout: nil)
      path = spec_path(slug)
      state = read_state(slug)
      evidence = { 'slug' => slug, 'started_at' => Time.now.utc.iso8601, 'command' => setting('testing', 'test_command'),
                   'result' => 'unverified', 'acceptance_criteria_proven' => false }
      begin
        configured!
        validate_spec(path, strict: true)
        evidence['fingerprint'] = fingerprint
        evidence['commit'] = git('rev-parse', '--verify', 'HEAD', allow_failure: true).strip
        raise Error, 'execution is paused; resume explicitly' if paused?(slug)
        raise Error, 'ci.run_tests is false' if ci && !enabled('ci', 'run_tests')
        command = evidence['command']
        raise Error, 'testing.test_command must be a nonempty configured string' unless meaningful?(command)
        if enabled('testing', 'require_tests')
          files = git('ls-files', '--cached', '--others', '--exclude-standard', '-z').split("\0")
          raise Error, 'no test files found; configure testing.test_patterns' unless files.any? { |file| test_file?(file) && File.file?(File.join(root, file)) }
        end
        timeout ||= setting('verification', 'timeout_seconds', default: 300)
        positive_number(timeout, 'verification.timeout_seconds')
        token = "#{Time.now.utc.strftime('%Y%m%dT%H%M%S')}-#{Process.pid}-#{Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)}"
        log = File.join(runtime_dir(slug), "#{token}.log")
        execution = process_command(command, log, timeout, slug)
        evidence.merge!(execution)
        evidence['log'] = log.delete_prefix(root + '/')
        if execution['termination']
          evidence['blocker'] = execution['termination']
        elsif fingerprint != evidence['fingerprint']
          evidence['blocker'] = 'inputs changed during verification'
        elsif execution['exit_code'] == 0
          evidence['result'] = 'passed'
        else
          evidence['result'] = 'failed'
          evidence['blocker'] = 'test command failed'
        end
      rescue Error, SystemCallError => exception
        evidence['blocker'] = exception.message
      end
      evidence['finished_at'] = Time.now.utc.iso8601
      record = File.join(runtime_dir(slug), "verify-#{Process.clock_gettime(Process::CLOCK_MONOTONIC, :nanosecond)}.json")
      atomic_json(record, evidence)
      state.merge!(evidence.slice('result', 'fingerprint', 'blocker'))
      state['blocker'] = evidence['blocker']
      state['fingerprint'] = evidence['fingerprint']
      state['last_evidence'] = record.delete_prefix(root + '/')
      state['next_step'] = evidence['result'] == 'passed' ? 'human_review' : 'resolve_blocker'
      state['phase'] = paused?(slug) ? 'paused' : 'idle'
      save_state(slug, state)
      puts "#{slug}: #{evidence['result']}#{evidence['blocker'] ? ': ' + evidence['blocker'] : ''}"
      return 0 if evidence['result'] == 'passed'
      return 0 if ci && evidence['result'] == 'failed' && !enabled('ci', 'fail_on_test_failure')
      return 0 if ci && evidence['blocker'] == 'ci.run_tests is false'
      evidence['result'] == 'failed' ? 1 : 2
    end

    def status(slug = nil)
      if slug.nil?
        active = File.join(runtime_dir, 'active.json')
        raise Error, 'no active spec; specify a slug' unless File.exist?(active)
        slug = JSON.parse(File.read(active)).fetch('slug')
      end
      state = read_state(slug)
      state['stale'] = state['fingerprint'].nil? || state['fingerprint'] != fingerprint
      if state['stale']
        state['last_result'] = state['result']
        state['result'] = 'unverified'
        state['next_step'] = 'verify'
        state['blocker'] = 'evidence is absent or inputs changed'
      end
      if paused?(slug)
        state['phase'] = 'paused'
        state['next_step'] = 'resume'
      end
      puts JSON.pretty_generate(state)
      state
    end

    def pause(slug)
      FileUtils.mkdir_p(runtime_dir(slug), mode: 0700)
      File.open(File.join(runtime_dir(slug), 'pause'), 'w', 0600) { |file| file.puts(Time.now.utc.iso8601) }
      puts "#{slug}: pause requested"
      0
    end

    def run(slug, resume: false)
      configured!
      validate_spec(spec_path(slug), strict: true)
      raise Error, 'execution.enabled must be explicitly true' unless enabled('execution', 'enabled', default: false)
      adapter = setting('execution', 'adapter')
      raise Error, 'execution.adapter must name a configured adapter' unless adapter.is_a?(String) && adapter.match?(/\A[a-z0-9_-]+\z/)
      command = setting('execution', 'adapters', adapter, 'command')
      raise Error, 'adapter command is not configured' unless meaningful?(command)
      cap = positive_number(setting('execution', 'max_cost', default: 0), 'execution.max_cost')
      cost = positive_number(setting('execution', 'adapters', adapter, 'max_cost_per_attempt', default: 0), 'adapter.max_cost_per_attempt')
      limit = positive_number(setting('execution', 'max_seconds', default: 600), 'execution.max_seconds')
      attempts = setting('execution', 'max_attempts', default: 1)
      raise Error, 'execution.max_attempts must be a positive integer' unless attempts.is_a?(Integer) && attempts > 0
      state = read_state(slug)
      raise Error, 'execution already started; use run <slug> --resume' if state['attempts'] > 0 && !resume
      raise Error, 'execution is paused; use --resume' if paused?(slug) && !resume
      FileUtils.rm_f(File.join(runtime_dir(slug), 'pause')) if resume
      return 0 if state['result'] == 'passed' && state['fingerprint'] == fingerprint
      loop do
        state = read_state(slug)
        blocker = if paused?(slug)
                    'paused'
                  elsif state['attempts'] >= attempts
                    'attempt limit reached'
                  elsif state['reserved_cost'] + cost > cap + 1e-9
                    'reserved cost limit reached'
                  elsif state['elapsed_seconds'] >= limit
                    'time limit reached'
                  end
        if blocker
          state.merge!('blocker' => blocker, 'phase' => blocker == 'paused' ? 'paused' : 'blocked', 'next_step' => 'human_review')
          save_state(slug, state)
          puts "#{slug}: #{blocker}"
          return 2
        end
        remaining = limit - state['elapsed_seconds']
        state['attempts'] += 1
        state['reserved_cost'] += cost
        state['elapsed_seconds'] += remaining
        state.merge!('phase' => 'running', 'result' => 'unverified', 'next_step' => 'verify', 'blocker' => nil)
        save_state(slug, state)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        config_before = File.binread(File.join(root, '.openspec/config.yaml'))
        spec_before = File.binread(File.join(root, spec_path(slug)))
        log = File.join(runtime_dir(slug), "adapter-#{state['attempts']}.log")
        execution = process_command(command, log, remaining, slug)
        state['adapter_result'] = execution.merge('command' => command, 'log' => log.delete_prefix(root + '/'))
        changed_contract = !File.file?(File.join(root, '.openspec/config.yaml')) || !File.file?(File.join(root, spec_path(slug))) ||
               config_before != File.binread(File.join(root, '.openspec/config.yaml')) || spec_before != File.binread(File.join(root, spec_path(slug)))
        if execution['termination'] || execution['exit_code'] != 0 || changed_contract
          state['blocker'] = changed_contract ? 'adapter changed spec or configuration; human review required' : (execution['termination'] || 'adapter failed')
          state['phase'] = paused?(slug) ? 'paused' : 'blocked'
          state['next_step'] = 'human_review'
          state['elapsed_seconds'] -= remaining - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
          save_state(slug, state)
          return 2
        end
        save_state(slug, state)
        available = remaining - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
        result = available > 0 ? verify(slug, timeout: [available, setting('verification', 'timeout_seconds', default: 300)].min) : 2
        state = read_state(slug)
        state['elapsed_seconds'] -= remaining - (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started)
        save_state(slug, state)
        return 0 if result == 0
        return 2 if result == 2
      end
    end
  end
end
