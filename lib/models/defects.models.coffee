##########################################
if Meteor.isServer
	syssrv.deleteDefect = (defectId, projectId) ->
		defect = db.defects.findOne({_id: defectId})
		planSummary = db.plan_summary.findOne({'projectId': projectId})

		#This part deletes the defect injected and removed values
		injectedValues = planSummary.injectedEstimated
		removedValues = planSummary.removedEstimated

		newInjected = planSummary.total.totalInjected-1
		newRemoved = planSummary.total.totalRemoved-1

		(_.findWhere injectedValues, {'name': defect.injected}).injected -= 1
		(_.findWhere removedValues, {'name': defect.removed}).removed -= 1
		db.plan_summary.update({'projectId': projectId}, {$set: {'injectedEstimated': injectedValues, 'removedEstimated': removedValues, 'total.totalInjected':newInjected, 'total.totalRemoved':newRemoved}})

		# Deletes the defect completely
		db.defects.remove({_id: defectId})

		# This changes the parentId value of all the defects that had this deleted defect as parent
		db.defects.update({parentId: defectId}, {$set: {parentId: null}},{multi:true})


##########################################