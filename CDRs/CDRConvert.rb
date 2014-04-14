#!/usr/bin/ruby

require 'json'

if !Dir.exists?("./Json")
  Dir.mkdir("./Json")
end

Dir["./Ascii/*"].each { |file|
  wholefile = "{"
  closeSymbolStack = Array.new
  firstElem = true
  # We will add commas before any element that isn't first in a container

  lines = IO.readlines file
  lines.each_with_index {|line, index|
    line.rstrip!.lstrip!
    line.gsub!('"', '\\\"')
    partition = line.partition ":"
    if partition[1].include? ":"
      #This is it's own key->value entry. Add in it's entirety
      if (!firstElem)
        wholefile += ','
      else
        firstElem = false
      end
      wholefile += '"'+ partition[0].rstrip + '" : "' + partition[2].lstrip + '"'
    elsif line.include? '{'
      #Beginning of either hash or array. Look ahead to figure out which
      if (!firstElem)
        wholefile += ','
      else
        firstElem = false
      end

      if lines[index+1].include? '['
        wholefile += '['
        closeSymbolStack.push ']'
      else
        wholefile += '{'
        closeSymbolStack.push '}'
      end
      firstElem = true

    elsif line.include? '}'
      #End of either hash or array. Pop closing object from stack
      wholefile += closeSymbolStack.pop

    elsif line.include? '['
      # [] are only used for array indices, simply ignore

    else
     # This is the key value, to a value of either hash or array
      if (!firstElem)
        wholefile += ','
      else
        firstElem = false
      end  
      wholefile += '"' + line + '"'
      wholefile += " : "
      firstElem = true
    end
  }

  wholefile += '}'
  cdrObj = JSON.parse wholefile
  
  File.open("./Json/"+ File.basename(file), 'w') { |file|
    file.write(JSON.pretty_generate cdrObj);
  }
  #puts JSON.parse wholefile
}
