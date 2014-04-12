c = require './schemas'
metaschema = require './metaschema'

jitterSystemCode = """
class Jitter extends System
  constructor: (world, config) ->
    super world, config
    @idlers = @addRegistry (thang) -> thang.exists and thang.acts and thang.moves and thang.action is 'idle'

  update: ->
    # We return a simple numeric hash that will combine to a frame hash
    # help us determine whether this frame has changed in resimulations.
    hash = 0
    for thang in @idlers
      hash += thang.pos.x += 0.5 - Math.random()
      hash += thang.pos.y += 0.5 - Math.random()
      thang.hasMoved = true
    return hash
"""

PropertyDocumentationSchema = c.object {
  title: "Property Documentation"
  description: "Documentation entry for a property this System will add to its Thang which other Systems
 might want to also use."
  "default":
    name: "foo"
    type: "object"
    description: "This System provides a 'foo' property to satisfy all one's foobar needs. Use it wisely."
  required: ['name', 'type', 'description']
},
  name: {type: 'string', pattern: c.identifierPattern, title: "Name", description: "Name of the property."}
  # not actual JS types, just whatever they describe...
  type: c.shortString(title: "Type", description: "Intended type of the property.")
  description: {type: 'string', description: "Description of the property.", maxLength: 1000}
  args: c.array {title: "Arguments", description: "If this property has type 'function', then provide documentation for any function arguments."}, c.FunctionArgumentSchema

DependencySchema = c.object {
  title: "System Dependency"
  description: "A System upon which this System depends."
  "default":
    #original: ?
    majorVersion: 0
  required: ["original", "majorVersion"]
  format: 'latest-version-reference'
  links: [{rel: "db", href: "/db/level.system/{(original)}/version/{(majorVersion)}"}]
},
  original: c.objectId(title: "Original", description: "A reference to another System upon which this System depends.")
  majorVersion:
    title: "Major Version"
    description: "Which major version of the System this System needs."
    type: 'integer'
    minimum: 0

LevelSystemSchema = c.object {
  title: "System"
  description: "A System which can affect Level behavior."
  required: ["name", "description", "code", "dependencies", "propertyDocumentation", "language"]
  "default":
    name: "JitterSystem"
    description: "This System makes all idle, movable Thangs jitter around."
    code: jitterSystemCode
    language: "coffeescript"
    dependencies: []  # TODO: should depend on something by default
    propertyDocumentation: []
}
c.extendNamedProperties LevelSystemSchema  # let's have the name be the first property
LevelSystemSchema.properties.name.pattern = c.classNamePattern
_.extend LevelSystemSchema.properties,
  description:
    title: "Description"
    description: "A short explanation of what this System does."
    type: "string"
    maxLength: 2000
    "default": "This System doesn't do anything yet."
  language:
    type: "string"
    title: "Language"
    description: "Which programming language this System is written in."
    "enum": ["coffeescript"]
  code:
    title: "Code"
    description: "The code for this System, as a CoffeeScript class. TODO: add link to documentation
 for how to write these."
    "default": jitterSystemCode
    type: "string"
    format: "coffee"
  js:
    title: "JavaScript"
    description: "The transpiled JavaScript code for this System"
    type: "string"
    format: "hidden"
  dependencies: c.array {title: "Dependencies", description: "An array of Systems upon which this System depends.", "default": [], uniqueItems: true}, DependencySchema
  propertyDocumentation: c.array {title: "Property Documentation", description: "An array of documentation entries for each notable property this System will add to its Level which other Systems might want to also use.", "default": []}, PropertyDocumentationSchema
  configSchema: _.extend metaschema, {title: "Configuration Schema", description: "A schema for validating the arguments that can be passed to this System as configuration.", default: {type: 'object', additionalProperties: false}}
  official:
    type: "boolean"
    title: "Official"
    description: "Whether this is an official CodeCombat System."
    "default": false

c.extendBasicProperties LevelSystemSchema, 'level.system'
c.extendSearchableProperties LevelSystemSchema
c.extendVersionedProperties LevelSystemSchema, 'level.system'
c.extendPermissionsProperties LevelSystemSchema
c.extendPatchableProperties LevelSystemSchema

module.exports = LevelSystemSchema
