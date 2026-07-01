# Checks core/manifest.rb against the files on disk: every core/**/*.rb (except manifest.rb itself) must be
# listed exactly once, and every listed entry must have a file. Catches the two failure modes that have bitten
# releases -- a new reader added but not registered (loads nowhere) and a manifest entry whose file was moved
# or renamed (NameError at boot). A pure-filesystem check, no engine stubs needed; exits non-zero on any gap.
ROOT = File.expand_path("../..", __dir__)
CORE = File.join(ROOT, "core")
MF   = File.join(CORE, "manifest.rb")

# The module entries listed in the manifest, as "subsystem/name" strings.
def manifest_entries
  src = File.read(MF)
  body = src[/%w\[(.*?)\]/m, 1] or abort "manifest_check: could not find the %w[...] list in #{MF}"
  body.split(/\s+/).reject { |s| s.empty? }
end

# Every core/**/*.rb as "subsystem/name" (manifest-relative, no extension), excluding the manifest itself.
def disk_modules
  Dir.glob(File.join(CORE, "**", "*.rb")).map do |p|
    p[(CORE.length + 1)..-1].sub(/\.rb\z/, "").tr("\\", "/")
  end.reject { |r| r == "manifest" }
end

entries = manifest_entries
disk    = disk_modules

missing_file = entries.reject { |e| File.file?(File.join(CORE, "#{e}.rb")) }
not_listed   = disk - entries
dupes        = entries.select { |e| entries.count(e) > 1 }.uniq

problems = []
problems << "listed but no file: #{missing_file.join(', ')}" unless missing_file.empty?
problems << "on disk but not listed: #{not_listed.join(', ')}" unless not_listed.empty?
problems << "listed more than once: #{dupes.join(', ')}" unless dupes.empty?

if problems.empty?
  puts "manifest_check: OK (#{entries.length} entries, all match disk)"
else
  puts "manifest_check: FAIL"
  problems.each { |p| puts "  - #{p}" }
  exit 1
end
