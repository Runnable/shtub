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
        local expected="_stub_data_${name}"
        local result=$(_stub::data::prefix "$name")
        assert equal "$expected" "$result"
      end
    end # prefix

    describe 'set'
      it 'should set the given data in the environment'
        local name='stub_name'
        local key='variable_key'
        local value='variable_value'
        local prefix=$(_stub::data::prefix "$name")
        _stub::data::set "$name" "$key" "$value"
        local variable_name="${prefix}_${key}"
        local result=$(eval "echo \$${variable_name}")
        assert equal "$value" "$result"
        eval "unset \$${variable_name}"
      end
    end # set

    describe 'get'
      it 'should return the requested information'
        local name='stub_name'
        local key='some_key'
        local value='wowza'
        _stub::data::set "$name" "$key" "$value"
        local result=$(_stub::data::get "$name" "$key")
        assert equal "$value" "$result"
        local variable_name="$(_stub::data::prefix "$name")_${key}"
        eval "unset \$${variable_name}"
      end
    end # get

    describe 'delete'
      it 'should delete the given key from the environment'
        local name='madbeatz'
        local key='rappers'
        local value='coolio'
        local prefix=$(_stub::data::prefix "$name")
        _stub::data::set "$name" "$key" "$value"
        _stub::data::delete "$name" "$key"
        local result=$(_stub::data::get "$name" "$key")
        assert equal '' "$result"
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
        _stub::data::delete "$name" 'call_count'
        _stub::data::delete "$name" 'last_args'
        _stub::data::delete "$name" 'default_stdout'
        _stub::data::delete "$name" 'default_stderr'
        _stub::data::delete "$name" 'default_command'
        _stub::data::delete "$name" 'default_status_code'
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
        local name='stub_name'
        local prefix=$(_stub::data::prefix "$name")
        eval "
          export ${prefix}_a=10
          export ${prefix}_b=20
          export ${prefix}_c=30
        "
        _stub::data::clear "$name"
        local a_val=$(_stub::data::get "$name" 'a')
        local b_val=$(_stub::data::get "$name" 'b')
        local c_val=$(_stub::data::get "$name" 'c')
        [ -z "$a_val" ] && [ -z "$b_val" ] && [ -z "$c_val" ]
        assert equal $? 0
      end

      it 'should not delete variables not associated with a stub'
        local name='stub_namezzz_yo'
        local prefix=$(_stub::data::prefix "$name")
        export _not_a_thing_yo=40
        _stub::data::set "$name" "a" 12304
        _stub::data::clear "$name"
        local a_val=$(_stub::data::get "$name" 'a')
        [ -z "$a_val" ] && [ -n "$_not_a_thing_yo" ]
        assert equal $? 0
        unset _not_a_thing_yo
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
