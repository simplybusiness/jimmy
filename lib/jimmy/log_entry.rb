module Jimmy
  class Entry < Hash
    def <<(hash)
      self.merge!(hash)
    end
  end
end
