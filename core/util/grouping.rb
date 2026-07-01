module PokeAccess
  module Util
    # Union-find (with path compression) over indices 0...n. The block decides whether two indices i, j
    # belong together; returns the list of index groups (each an Array of indices). Callers map the indices
    # back to their own elements and pick a representative -- this only owns the non-trivial grouping. The
    # double loop is O(n^2) in the merge test, matching the original inline versions (small n: emitters/exits
    # near the player). 1.8.7-safe.
    def self.union_groups(n)
      return [] if n <= 0
      parent = (0...n).to_a
      root = lambda do |i|
        while parent[i] != i; parent[i] = parent[parent[i]]; i = parent[i]; end
        i
      end
      (0...n).each do |i|
        ((i + 1)...n).each { |j| parent[root.call(i)] = root.call(j) if yield(i, j) }
      end
      groups = {}
      (0...n).each { |i| (groups[root.call(i)] ||= []).push(i) }
      groups.values
    end
  end
end
