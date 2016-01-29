#!/bin/bash

source './shtub.sh'

describe 'stub'
  # before
    stub 'woot'
  # end

  it 'should create a stub with no output'
    assert equal "$(woot)" ''
  end

  it 'should create a stub that returns 0'
    woot
    assert equal $? 0
  end

  # after
    woot::restore
  # end
end # stub

describe 'stub::returns'
  # before
    local output='grill'
    stub::returns 'dayum' "$output"
  # end

  it 'should create a stub that echo the given output'
    assert equal "$(dayum)" "$output"
  end

  it 'should create a stub that returns 0'
    dayum > /dev/null
    assert equal $? 0
  end

  # after
    dayum::restore
  # end
end # stub::returns

describe 'stub::errors'
  # before
    local output='notathingyo'
    local code=12
    stub::errors 'fool' "$output" $code
  # end

  it 'should create a stub that echos the given output to stderr'
    assert equal "$(fool 2>&1)" "$output"
  end

  it 'should create a stub that returns the given status code'
    fool
    assert equal $? $code
  end

  # after
    fool::restore
  # end
end # stub::errors

describe 'stub::exec'
  # before
    local called=0
    neato() { called=1; }
    stub::exec 'ooph' neato
  # end

  it 'should create a stub that executes the given function'
    ooph
    assert equal "$called" '1'
  end

  # after
    ooph::restore
    unset -f neato
  # end
end # stub::exec
