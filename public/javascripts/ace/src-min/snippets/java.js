define("ace/snippets/java",["require","exports","module"],function(e,t,n){"use strict";t.snippetText='## Access Modifiers\nsnippet po\n	protected\nsnippet pu\n	public\nsnippet pr\n	private\n##\n## Annotations\nsnippet before\n	@Before\n	static void ${1:intercept}(${2:args}) { ${3} }\nsnippet mm\n	@ManyToMany\n	${1}\nsnippet mo\n	@ManyToOne\n	${1}\nsnippet om\n	@OneToMany${1:(cascade=CascadeType.ALL)}\n	${2}\nsnippet oo\n	@OneToOne\n	${1}\n##\n## Basic Java packages and import\nsnippet im\n	import\nsnippet j.b\n	java.beans.\nsnippet j.i\n	java.io.\nsnippet j.m\n	java.math.\nsnippet j.n\n	java.net.\nsnippet j.u\n	java.util.\n##\n## Class\nsnippet cl\n	class ${1:`Filename("", "untitled")`} ${2}\nsnippet in\n	interface ${1:`Filename("", "untitled")`} ${2:extends Parent}${3}\nsnippet tc\n	public class ${1:`Filename()`} extends ${2:TestCase}\n##\n## Class Enhancements\nsnippet ext\n	extends \nsnippet imp\n	implements\n##\n## Comments\nsnippet /*\n	/*\n	 * ${1}\n	 */\n##\n## Constants\nsnippet co\n	static public final ${1:String} ${2:var} = ${3};${4}\nsnippet cos\n	static public final String ${1:var} = "${2}";${3}\n##\n## Control Statements\nsnippet case\n	case ${1}:\n		${2}\nsnippet def\n	default:\n		${2}\nsnippet el\n	else\nsnippet elif\n	else if (${1}) ${2}\nsnippet if\n	if (${1}) ${2}\nsnippet sw\n	switch (${1}) {\n		${2}\n	}\n##\n## Create a Method\nsnippet m\n	${1:void} ${2:method}(${3}) ${4:throws }${5}\n##\n## Create a Variable\nsnippet v\n	${1:String} ${2:var}${3: = null}${4};${5}\n##\n## Enhancements to Methods, variables, classes, etc.\nsnippet ab\n	abstract\nsnippet fi\n	final\nsnippet st\n	static\nsnippet sy\n	synchronized\n##\n## Error Methods\nsnippet err\n	System.err.print("${1:Message}");\nsnippet errf\n	System.err.printf("${1:Message}", ${2:exception});\nsnippet errln\n	System.err.println("${1:Message}");\n##\n## Exception Handling\nsnippet as\n	assert ${1:test} : "${2:Failure message}";${3}\nsnippet ca\n	catch(${1:Exception} ${2:e}) ${3}\nsnippet thr\n	throw\nsnippet ths\n	throws\nsnippet try\n	try {\n		${3}\n	} catch(${1:Exception} ${2:e}) {\n	}\nsnippet tryf\n	try {\n		${3}\n	} catch(${1:Exception} ${2:e}) {\n	} finally {\n	}\n##\n## Find Methods\nsnippet findall\n	List<${1:listName}> ${2:items} = ${1}.findAll();${3}\nsnippet findbyid\n	${1:var} ${2:item} = ${1}.findById(${3});${4}\n##\n## Javadocs\nsnippet /**\n	/**\n	 * ${1}\n	 */\nsnippet @au\n	@author `system("grep \\`id -un\\` /etc/passwd | cut -d \\":\\" -f5 | cut -d \\",\\" -f1")`\nsnippet @br\n	@brief ${1:Description}\nsnippet @fi\n	@file ${1:`Filename()`}.java\nsnippet @pa\n	@param ${1:param}\nsnippet @re\n	@return ${1:param}\n##\n## Logger Methods\nsnippet debug\n	Logger.debug(${1:param});${2}\nsnippet error\n	Logger.error(${1:param});${2}\nsnippet info\n	Logger.info(${1:param});${2}\nsnippet warn\n	Logger.warn(${1:param});${2}\n##\n## Loops\nsnippet enfor\n	for (${1} : ${2}) ${3}\nsnippet for\n	for (${1}; ${2}; ${3}) ${4}\nsnippet wh\n	while (${1}) ${2}\n##\n## Main method\nsnippet main\n	public static void main (String[] args) {\n		${1:/* code */}\n	}\n##\n## Print Methods\nsnippet print\n	System.out.print("${1:Message}");\nsnippet printf\n	System.out.printf("${1:Message}", ${2:args});\nsnippet println\n	System.out.println(${1});\n##\n## Render Methods\nsnippet ren\n	render(${1:param});${2}\nsnippet rena\n	renderArgs.put("${1}", ${2});${3}\nsnippet renb\n	renderBinary(${1:param});${2}\nsnippet renj\n	renderJSON(${1:param});${2}\nsnippet renx\n	renderXml(${1:param});${2}\n##\n## Setter and Getter Methods\nsnippet set\n	${1:public} void set${3:}(${2:String} ${4:}){\n		this.$4 = $4;\n	}\nsnippet get\n	${1:public} ${2:String} get${3:}(){\n		return this.${4:};\n	}\n##\n## Terminate Methods or Loops\nsnippet re\n	return\nsnippet br\n	break;\n##\n## Test Methods\nsnippet t\n	public void test${1:Name}() throws Exception {\n		${2}\n	}\nsnippet test\n	@Test\n	public void test${1:Name}() throws Exception {\n		${2}\n	}\n##\n## Utils\nsnippet Sc\n	Scanner\n##\n## Miscellaneous\nsnippet action\n	public static void ${1:index}(${2:args}) { ${3} }\nsnippet rnf\n	notFound(${1:param});${2}\nsnippet rnfin\n	notFoundIfNull(${1:param});${2}\nsnippet rr\n	redirect(${1:param});${2}\nsnippet ru\n	unauthorized(${1:param});${2}\nsnippet unless\n	(unless=${1:param});${2}\n',t.scope="java"});
                (function() {
                    window.require(["ace/snippets/java"], function(m) {
                        if (typeof module == "object" && typeof exports == "object" && module) {
                            module.exports = m;
                        }
                    });
                })();
            