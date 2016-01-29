#!/bin/bash

source './shtub.sh'

describe '_stub::methods'
  describe 'restore'
    it 'should restore the original command'
      stub 'echo'
      echo::restore
      assert equal $(echo hiya) 'hiya'
    end
  end # restore

  describe 'reset'
    it 'should reset the stub counts'
      stub 'ls'
      ls ; ls ; ls
      ls::reset
      assert equal $(_stub::data::get 'ls' 'call_count') '0'
      ls::restore
    end

    it 'should reset the stub arguments'
      stub 'ps'
      ps aux
      ps::reset
      assert equal $(_stub::data::get 'ps' 'last_args') ''
      ps::restore
    end
  end # reset

  describe 'returns'
    it 'should cause the stub to echo the given string'
      stub 'ls'
      ls::returns 'gtfo'
      assert equal $(ls) 'gtfo'
      ls::restore
    end
  end # returns

  describe 'errors'
    # before
      stub 'bad'
    # end

    it 'should cause the stub to error with the given output'
      local message='noooo'
      bad::errors "$message"
      assert equal "$(bad 2>&1)" "$message"
    end

    it 'should use the given error code'
      local code=122
      bad::errors 'nope' "$code"
      bad &> /dev/null
      assert equal "$?" "$code"
    end

    it 'should allow for empty stderr output'
      bad::errors
      assert equal "$(bad 2>&1)" ''
    end

    it 'should return an error code with empty output'
      bad::errors
      bad &> /dev/null
      assert equal "$?" '1'
    end

    it 'should allow for empty output with a status code'
      local code=111
      bad::errors "$code"
      bad &> /dev/null
      assert equal "$?" "$code"
    end

    # after
      bad::restore
    # end
  end # errors

  describe 'exec'
    it 'should cause the stub to execute the given function'
      local called=0
      callmemaybe() { called=1; }
      stub 'yus'
      yus::exec callmemaybe
      yus
      assert equal $called 1
      yus::restore
      unset -f callmemaybe
    end
  end # exec

  describe 'on_call'
    it 'should execute the function on the correct call'
      stub 'haygril'
      noway() { echo 'NO WAY'; }
      haygril::returns ''
      haygril::on_call 2 noway
      haygril
      assert equal "$(haygril)" 'NO WAY'
      haygril::restore
      unset -f noway
    end

    it 'should use the default behavior on other calls'
      stub 'yoobro'
      nunuh() { echo 'nuup'; }
      yoobro::returns 'sup'
      yoobro::on_call 2 nunuh
      assert equal $(yoobro) 'sup'
      yoobro::restore
      unset -f noway
    end
  end # on_call

  describe 'called_with'
    it 'should pass if the stub was called with the given args'
      stub 'hi'
      hi a b c
      hi::called_with a b c
      assert equal $? 0
      hi::restore
    end

    it 'should pass if the stub was called with the given args and anything else'
      stub 'hi'
      hi a b c d e f g
      hi::called_with a b c
      assert equal $? 0
      hi::restore
    end

    it 'should fail if the stub was not called with the given args'
      stub 'hi'
      hi b b c
      hi::called_with a b c
      assert equal $? 1
      hi::restore
    end
  end # called_with

  describe 'called'
    it 'should pass if the stub was called'
      stub 'yo'
      yo
      yo::called
      assert equal $? 0
      yo::restore
    end

    it 'should fail if the stub was not called'
      stub 'yo'
      yo::called
      assert equal $? 1
      yo::restore
    end

    it 'should pass if the stub was called the given number of times'
      stub 'yo'
      yo ; yo
      yo::called 2
      assert equal $? 0
      yo::restore
    end

    it 'should fail if the stub was not called the given number of times'
      stub 'yo'
      yo ; yo ; yo
      yo::called 5
      assert equal $? 1
      yo::restore
    end
  end # called

  describe 'not_called'
    it 'should pass if the stub was not called'
      stub 'wooowoooo'
      wooowoooo::not_called
      assert equal $? 0
      wooowoooo::restore
    end

    it 'should fail if the stub was called'
      stub 'wooowoooo'
      wooowoooo
      wooowoooo::not_called
      assert equal $? 1
      wooowoooo::restore
    end
  end # not_called

  describe 'called_once'
    it 'should pass if the stub was called exactly once'
      stub 'cool'
      cool
      cool::called_once
      assert equal $? 0
      cool::restore
    end

    it 'should fail if the stub was not called'
      stub 'cool'
      cool::called_once
      assert equal $? 1
      cool::restore
    end

    it 'should fail if the stub was called a different number of times'
      stub 'cool'
      cool ; cool
      cool::called_once
      assert equal $? 1
      cool::restore
    end
  end # called_once

  describe 'called_twice'
    it 'should pass if the stub was called exactly twice'
      stub 'cool'
      cool ; cool
      cool::called_twice
      assert equal $? 0
      cool::restore
    end

    it 'should fail if the stub was not called'
      stub 'cool'
      cool::called_twice
      assert equal $? 1
      cool::restore
    end

    it 'should fail if the stub was called less than twice'
      stub 'cool'
      cool
      cool::called_twice
      assert equal $? 1
      cool::restore
    end

    it 'should fail if the stub was called a different number of times'
      stub 'cool'
      cool ; cool ; cool
      cool::called_twice
      assert equal $? 1
      cool::restore
    end
  end # called_twice

  describe 'called_thrice'
    it 'should pass if the stub was called exactly thrice'
      stub 'cool'
      cool ; cool ; cool
      cool::called_thrice
      assert equal $? 0
      cool::restore
    end

    it 'should fail if the stub was not called'
      stub 'cool'
      cool::called_thrice
      assert equal $? 1
      cool::restore
    end

    it 'should fail if the stub was called less than thrice'
      stub 'cool'
      cool ; cool
      cool::called_thrice
      assert equal $? 1
      cool::restore
    end

    it 'should fail if the stub was called a different number of times'
      stub 'cool'
      cool ; cool ; cool ; cool ; cool
      cool::called_thrice
      assert equal $? 1
      cool::restore
    end
  end # called_thrice
end # _stub::methods
