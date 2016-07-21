##########################################
if Meteor.isServer
	syssrv.createPlanSummary = (userId, projectId, levelPSP) ->
		timePlanSummary = Meteor.settings.public.timeEstimated
		Injected = Meteor.settings.public.InjectedEstimated
		Removed = Meteor.settings.public.RemovedEstimated

		if levelPSP == 'PSP 2'
			timePlanSummary.splice(2, 0, {"name":"Revisión Diseño", "finished":false, "time":0})
			timePlanSummary.splice(4, 0, {"name":"Revisión Código", "finished":false, "time":0})

			Injected.splice(2, 0, {"name":"Revisión Diseño", "injected":0, "estimated": 0})
			Injected.splice(4, 0, {"name":"Revisión Código", "injected":0, "estimated": 0})

			Removed.splice(2, 0, {"name":"Revisión Diseño", "removed":0, "estimated": 0})
			Removed.splice(4, 0, {"name":"Revisión Código", "removed":0, "estimated": 0})

		user = db.users.findOne({_id: Meteor.userId()}).profile
		historyTotalTime = user.total.time
		console.log historyTotalTime
		historyTotalInjected = user.total.injected
		historyTotalRemoved = user.total.removed

		finishedProjects = db.projects.find({"projectOwner": Meteor.userId()}, "completed": true).count()

		# This will add to the time the toDate and toDate% fields for the Plan Summary
		finalTime = _.filter timePlanSummary, (time) ->
			onDate = _.findWhere user.summaryAmount, {name: time.name}
			time.toDate = onDate.time
			if (onDate.time == 0) or (historyTotalTime == 0)
				time.percentage = 0
				time.average = 0
			else
				time.percentage = ((onDate.time * 100) / historyTotalTime).toFixed(2)
				time.average = (onDate.time/finishedProjects).toFixed(2)

			return time
		#console.log finalTime

		finalInjected = _.filter Injected, (injected) ->
			onDate = _.findWhere user.summaryAmount, {name: injected.name}
			injected.toDate = onDate.injected
			if (onDate.injected == 0) or (historyTotalInjected == 0)
				injected.percentage = 0
			else
				injected.percentage = ((onDate.injected * 100) / historyTotalInjected).toFixed(2)
			return injected

		finalRemoved = _.filter Removed, (removed) ->
			onDate = _.findWhere user.summaryAmount, {name: removed.name}
			removed.toDate = onDate.removed
			if (onDate.removed == 0) or (historyTotalRemoved == 0)
				removed.percentage = 0
			else
				removed.percentage = ((onDate.removed * 100) / historyTotalRemoved).toFixed(2)
			return removed


		data = {
			summaryOwner: userId
			projectId: projectId
			createdAt: new Date()
			timeEstimated: finalTime
			injectedEstimated: finalInjected
			removedEstimated: finalRemoved
			total:
				totalTime: 0
				estimatedTime: 0
		}

		db.plan_summary.insert(data)



##########################################