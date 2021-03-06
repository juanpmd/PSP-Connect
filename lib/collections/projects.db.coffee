##########################################
db.projects = new Meteor.Collection "Projects"
##########################################
############## Main Schema ###############
schemas.projects = new SimpleSchema
	"title":
		type: String
		label: "Title of the Project"

	"description":
		type: String
		label: "Description of the project"

	"projectOwner":
		type: String
		label: "User who created the project"

	"parentId":
		type: String
		optional: true
		label: "Parent project id"

	"createdAt":
		type: Date
		label: "Date when the project was created"
		autoValue: (doc) ->
			if @isInsert
				return new Date()

	"completedAt":
		type: Date
		label: "Date when the project was completed"
		optional: true

	"levelPSP":
		type: String
		label: "Level of PSP of the project"

	"completed":
		type: Boolean
		label: "If the project was finished or not"
		autoValue: (doc) ->
			if @isInsert
				return false

	"color":
		type: String
		optional: true
		label: "Color of the project"

	"defectTypesId":
		type: String
		optional: true
		label: "Id of the defect types file used"

	"projectProbe":
		type: String
		optional: true
		label: "Used probe for the Project"

##########################################
db.projects.attachSchema(schemas.projects)
##########################################