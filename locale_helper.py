import os
import luaparser
import luaparser.ast
import luaparser.astnodes
import pprint

if __name__ == "__main__":
    os.chdir(os.path.dirname(__file__))
    src = open("control.lua", encoding="utf-8").read()
    tree = luaparser.ast.parse(src)
    # print(luaparser.ast.to_pretty_str(tree))

    strings = []
    # classes = set()
    for node in luaparser.ast.walk(tree):
        # classes |= {node.__class__}
        if not hasattr(node, "visited"):
            node.visited = False

        def chain_concat_extractor(node):
            # print(node.__class__)
            node.visited = True
            if node.__class__ == luaparser.astnodes.Concat:
                # print("Concat")
                return chain_concat_extractor(node.left) + chain_concat_extractor(
                    node.right
                )
            elif node.__class__ == luaparser.astnodes.String:
                return [node.s]
            else:
                return ["PARAMETER"]

        if not node.visited and node.__class__ == luaparser.astnodes.Concat:
            strings[chain_concat_extractor(node)] = node
        if not node.visited and isinstance(node, luaparser.ast.String):
            strings[node.s] = node
    # print(classes)
    locales = []
    for string in strings:
        if isinstance(string, list):
            cnt = 1
            for i in range(len(string)):
                if string[i] == "PARAMETER":
                    string[i] = f"__{cnt}__"
                    cnt += 1
            string = "".join(string)
        print(string)
        if any(map(lambda x: ord(x) > 127, string)):
            locales.append(string)
    dictionary = {}
    for locale in locales:
        print(locale)
        key = input("Key: ")
        dictionary[key] = locale
    pprint.pprint(dictionary)
    with open("tmp_locale.cfg", "w", encoding="utf-8") as f:
        for key, value in dictionary.items():
            f.write(f"{key}={repr(value)[1:-1]}\n")
