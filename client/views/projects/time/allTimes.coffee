##########################################
openStageStatus = new ReactiveVar(false)

##########################################
Template.timeTemplate.helpers
	projectStages: () ->
		return db.plan_summary.findOne({projectId: FlowRouter.getParam("id")})?.timeEstimated

##########################################
Template.timesBar.onCreated () ->
	@disablePlayButton = new ReactiveVar(false)


Template.timesBar.helpers
	planSummary: () ->
		return db.plan_summary.findOne({projectId: FlowRouter.getParam("id")})

	isRecordingTime:() ->
		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id"), "summaryOwner": Meteor.userId()})
		return planSummary?.timeStarted != "false"

	currentStage: () ->
		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id")})
		projectStages = _.filter planSummary?.timeEstimated, (stage) ->
			unless stage.finished
				return stage

		currentPos = _.first(projectStages)?.name

		unless currentPos
			Template.instance().disablePlayButton.set(true)

		return currentPos

	disabledPlayButton: () ->
		projectIsCompleted = db.projects.findOne({ _id: FlowRouter.getParam("id") })?.completed
		disableRecording = Template.instance().disablePlayButton.get()

		return true if projectIsCompleted
		return true if disableRecording
		return false

	projectIsCompleted: () ->
		return db.projects.findOne({ _id: FlowRouter.getParam("id") })?.completed

	openStageStatus: () ->
		return openStageStatus.get()

	availableOpenStage: () ->
		project = db.projects.findOne({_id: FlowRouter.getParam("id")})
		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id")})
		projectProbe = project?.projectProbe

		projectStages = _.filter planSummary?.timeEstimated, (stage) ->
			unless stage.finished
				return stage

		currentStage = _.first projectStages

		return false if currentStage?.name == "Planeación" and @total.estimatedTime == 0 and projectProbe == "probeD" and project?.levelPSP == "PSP 0"
		return true


Template.timesBar.events
	'click .fa-play': (e,t) ->
		project = db.projects.findOne({ _id: FlowRouter.getParam("id") })

		unless t.disablePlayButton.get() or project?.completed
			date = new Date()

			Meteor.call "update_timeStarted", FlowRouter.getParam("id"), date, (error) ->
				if error
					console.log "Error changing timeStarted in plan Summary"
				else
					projectId = FlowRouter.getParam("fid")
					iterationId = FlowRouter.getParam("id")
					sys.flashTime(project.title, projectId, iterationId)


	'click .fa-pause': (e,t) ->
		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id")})
		projectStages = _.filter planSummary?.timeEstimated, (stage) ->
			unless stage.finished
				return stage

		unless @timeStarted == "false"
			totalTime = new Date() - new Date(@timeStarted)
			currentStage = _.first projectStages
			currentStage.time = parseInt(totalTime)

			Meteor.call "update_time_stage", FlowRouter.getParam("id"), currentStage, false, true, (error) ->
				if error
					console.warn(error)
					sys.flashStatus("error-new-time-project")
				else
					sys.flashStatus("new-time-project")
					sys.removeTimeMessage()


	'click .time-submit': (e,t) ->
		project = db.projects.findOne({_id: FlowRouter.getParam("id")})
		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id")})
		projectProbe = project?.projectProbe

		projectStages = _.filter planSummary?.timeEstimated, (stage) ->
			unless stage.finished
				return stage

		currentStage = _.first projectStages

		# If the user has the probeD option and has not entered a value in the Plan Summary estimation,
		# This will give it a error and not let the user finish the stage "Planeación"
		if currentStage.name == "Planeación" and @total.estimatedTime == 0 and projectProbe == "probeD" and project.levelPSP == "PSP 0"
			sys.flashStatus("summary-missing")

		else
			if @timeStarted != "false"
				totalTime = new Date() - new Date(@timeStarted)
			else
				totalTime = 0

			currentStage.time = parseInt(totalTime)

			Meteor.call "update_time_stage", FlowRouter.getParam("id"), currentStage, true, true, (error) ->
				if error
					console.warn(error)
					sys.flashStatus("error-submit-stage-project")
				else
					sys.flashStatus("submit-stage-project")
					sys.removeTimeMessage()

	'click .reopen-stage': (e,t) ->
		openStatus = openStageStatus.get()
		openStageStatus.set(!openStatus)


##################################################
Template.timeTableRow.helpers
	editAvailable: () ->
		project = db.projects.findOne({ _id: FlowRouter.getParam("id") })
		return false if project?.completed
		return true if @finished

		planSummary = db.plan_summary.findOne({"projectId": FlowRouter.getParam("id")})
		projectStages = _.filter planSummary?.timeEstimated, (stage) ->
			unless stage.finished
				return stage

		return true if @name == _.first(projectStages)?.name
		return false

	openStageStatus: () ->
		return openStageStatus.get()


Template.timeTableRow.events
	'click .edit-time': (e,t) ->
		Modal.show('editTimeModal', @)

	'click .time-stage-status': (e,t) ->
		currentStage = @
		Meteor.call "update_stage_completed_value", FlowRouter.getParam("id"), currentStage, (error) ->
			if error
				console.warn(error)
				sys.flashStatus("error-submit-stage-project")
			else
				sys.flashStatus("submit-stage-project")


##########################################