package lua

import (
	"errors"
	"fmt"
	"github.com/mtabini/go-lua"
	"github.com/mtabini/goluago"
	"github.com/mtabini/goluago/util"
	"regexp"
)

const arrayMarkerField = "_is_array"

var errorRegex = regexp.MustCompile(`:([^:]+)+:(.+)$`)

func Exec(source string, np notificationProvider, args map[string]interface{}) (map[string]interface{}, error) {
	l := lua.NewState()

	lua.OpenLibraries(l)
	goluago.Open(l)

	openJSONLibrary(l)
	openHTTPLibrary(l)
	openStorageLibrary(l)
	openNotificationsLibrary(l, np)

	util.DeepPush(l, args)

	l.SetGlobal("args")

	util.DeepPush(l, map[string]interface{}{})

	l.SetGlobal("output")

	err := lua.LoadString(l, source)

	if err != nil {
		matches := errorRegex.FindStringSubmatch(lua.CheckString(l, -1))
		return nil, fmt.Errorf("Parse error on line %s: %s", matches[1], matches[2])
	}

	err = l.ProtectedCall(0, 0, 0)

	if err != nil {
		matches := errorRegex.FindStringSubmatch(lua.CheckString(l, -1))
		return nil, fmt.Errorf("Runtime error on line %s: %s", matches[1], matches[2])
	}

	l.Global("output")

	defer l.Pop(1)

	table, err := util.PullTable(l, 1)

	if err != nil {
		return nil, err
	}

	if output, ok := table.(map[string]interface{}); ok {
		return output, err
	} else {
		if err == nil {
			return nil, errors.New("The output global has been overwritten with something other than a table.")
		}

		return nil, err
	}
}
