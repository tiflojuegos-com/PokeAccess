# Native RMXP loader (fallback for games without mkxp-z). Requires Ruby 1.8.7+: the core relies on
# 1.8.7 methods (min_by/max_by), so the stock RMXP 1.8.1 interpreter is not enough -- the game must ship
# a 1.8.7-compatible Ruby. Injected into Scripts.rxdata just before "Main" by a packing step, when all
# classes are already defined. It only evaluates accessibility/boot.rb; the real code is external. eval
# is intentional and safe (boot.rb is our own trusted file in a fixed folder).
begin
  path = "accessibility/boot.rb"
  if File.exist?(path)
    eval(File.read(path), TOPLEVEL_BINDING, path)
  end
rescue Exception => e
  raise if e.is_a?(SystemExit)
  begin
    File.open("accessibility/data/loader_error.txt", "w") do |f|
      f.write("#{e.class}: #{e.message}\n")
      f.write((e.backtrace || []).join("\n"))
    end
  rescue StandardError
  end
end
