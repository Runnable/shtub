#!/bin/bash

source "./shtub.sh"

describe '_stub'
  local method_names="
    restore
    reset
    returns
    errors
    exec
    called_with
    called
    not_called
    called_once
    called_twice
    called_thrice
    on_call
  "

  describe 'data'
    describe 'prefix'
      it 'should echo the correct stub data prefix'
        local name='some_stubbed_command'
        local expected="{${name}}"
        local result=$(_stub::data::prefix "$name")
        assert equal "$expected" "$result"
      end

      it 'should echo the correct key value prefix'
        local name='stubbed'
        local key='keyname'
        local expected="{${name}}.${key}"
        assert equal "$expected" "$(_stub::data::prefix $name $key)"
      end
    end # prefix

    describe 'set'
      it 'should set the value for the given key'
        echo '' > .stubdata
        _stub::data::set 'name' 'key' 'value'
        local was_set=$(grep '{name}.key=value' .stubdata | wc -l | sed 's/ //g')
        assert equal "$was_set" "1"
      end

      it 'should allow slashes in the value'
        echo '' > .stubdata
        _stub::data::set 'name' 'key' 'initial'
        _stub::data::set 'name' 'key' '/this/path/should/work'
        local was_set=$(grep '/this/path/should/work' .stubdata | wc -l | sed 's/ //g')
        assert equal "$was_set" "1"
      end
    end # set

    describe 'get'
      it 'should return the requested information'
        echo '{name}.key=1234' > .stubdata
        assert equal "1234" "$(_stub::data::get 'name' 'key')"
      end
    end # get

    describe 'delete'
      it 'should delete the given key from the environment'
        echo '{name}.key=alpha' > .stubdata
        _stub::data::delete 'name' 'key'
        assert equal '' "$(_stub::data::get 'name' 'key')"
      end
    end # delete

    describe 'init'
      # before
        local name='some_stub'
        _stub::data::init "$name"
      #

      it 'should set the call count for the stub'
        local result=$(_stub::data::get "$name" 'call_count')
        assert equal '0' "$result"
      end

      it 'should set the last arguments for the stub'
        local result=$(_stub::data::get "$name" 'last_args')
        assert equal '' "$result"
      end

      it 'should set the default stdout message'
        local result=$(_stub::data::get "$name" 'default_stdout')
        assert equal '' "$result"
      end

      it 'should set the default stderr message'
        local result=$(_stub::data::get "$name" 'default_stderr')
        assert equal '' "$result"
      end

      it 'should set the default status code'
        local result=$(_stub::data::get "$name" 'default_status_code')
        assert equal '0' "$result"
      end

      it 'should set the default default command'
        local result=$(_stub::data::get "$name" 'default_command')
        assert equal '' "$result"
      end

      # after
        _stub::data::clear "$name"
      #
    end # init

    describe 'reset'
      it 'should reset the call count for the stub'
        local name='wowzapalooza'
        _stub::data::set "$name" "call_count" 2
        _stub::data::reset "$name"
        local result=$(_stub::data::get "$name" 'call_count')
        assert equal '0' "$result"
        _stub::data::delete "$name" "call_count"
      end

      it 'should reset the last arguments for the stub'
        local name='wowzapalooza'
        _stub::data::set "$name" "last_args" 'a b -ls'
        _stub::data::reset "$name"
        local result=$(_stub::data::get "$name" 'last_args')
        assert equal '' "$result"
        _stub::data::delete "$name" "last_args"
      end
    end # reset

    describe 'clear'
      it 'should remove all variables associated with a stub'
        echo '{name}.alpha=1' > .stubdata
        echo '{name}.beta=2' >> .stubdata
        echo '{other}.wow=neat' >> .stubdata
        echo '{name}.gamma=3' >> .stubdata
        echo '{name}.delta=4' >> .stubdata
        _stub::data::clear 'name'
        local expected='{other}.wow=neat'
        assert equal "$expected" "$(cat .stubdata)"
      end

      it 'should clear all data when not given a name'
        echo 'aaa' > .stubdata
        echo 'aaa' >> .stubdata
        echo 'aaa' >> .stubdata
        _stub::data::clear
        assert equal '' "$(cat .stubdata)"
      end
    end # clear
  end # data

  describe 'remove'
    it 'should remove the stubbed function'
      local name='example'
      eval "${name}() { return 0; }"
      _stub::remove "$name"
      type -t "$name"
      assert equal $? 1
    end

    it 'should remove all stub methods'
      local name="foobar"
      for method in $method_names; do
        eval "${name}::${method}() { return 0; }"
      done

      _stub::remove "$name"

      local types=''
      for method in $method_names; do
        local method_name="${name}::${method}"
        types+=$(type -t "$method_name")
      done
      [ -z "$types" ]

      assert equal $? 0
    end

    it 'should remove all data associated with the stub'
      local name='stub_name'

      local keys="alpha beta gamma delta epsilon"
      for key in $keys; do
        _stub::data::set "$name" "$key" "1020030"
      done

      _stub::remove "$name"

      local values=''
      for key in $keys; do
        values+=$(_stub::data::get "$name" "$key")
      done

      [ -z "$values" ]
      assert equal $? 0
    end
  end # remove

  describe 'set_all_methods'
    it 'should set all of the methods for the stub'
      local name='omg'
      _stub::set_all_methods "$name"
      local result=0
      for method in $method_names; do
        local method_name="${name}::${method}"
        local method_type=$(type -t "$method_name")
        [ "function" == "$method_type" ]
        (( result = result + $? ))
      done
      assert equal "$result" '0'
    end
  end # set_all_methods
end # _stub
