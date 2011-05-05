module Utility
  def mean(array)
    array.inject(0) { |sum, x| sum += x } / array.size.to_f
  end

  def median(array, already_sorted=false)
    return nil if array.empty?
    array = array.sort unless already_sorted
    m_pos = array.size / 2
    return array.size % 2 == 1 ? array[m_pos] : mean(array[m_pos-1..m_pos])
  end
end
