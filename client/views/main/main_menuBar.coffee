##################################################
notSeenNotifications = new ReactiveVar({})
##################################################
Template.main_menuBar.onCreated () ->
	Meteor.subscribe "UserMenu"
	Session.set("display-user-box", false)
	Session.set("display-notification-box", false)

Template.main_menuBar.helpers
	template: () ->
		FlowRouter.watchPathChange()
		return FlowRouter.current().route.name

	isProjectView: () ->
		FlowRouter.watchPathChange()
		route = FlowRouter.current().route.name
		return (route == 'projects') or (route == 'iterations') or (route == 'projectView') or (route == "projectGeneral") or (route == "projectTimeLog") or (route == "projectDefectLog") or (route == "projectSummary") or (route == "projectScripts") or (route == "estimatingtemplate")

	isSettingsView: () ->
		FlowRouter.watchPathChange()
		route = FlowRouter.current().route.name
		return (route == 'projectSettings') or (route == 'accountSettings') or (route == 'defectTypeSettings')

	userData: () ->
		user = Meteor.users.findOne({_id: Meteor.userId()})
		return user if user?

	showNotificationBadge: () ->
		return db.notifications.find({"notificationOwner": Meteor.userId(), "seen": false}).count() > 0


Template.main_menuBar.events
	'click .avatar': (e,t) ->
		e.preventDefault()
		e.stopPropagation()

		if Session.get("display-user-box")
			Session.set("display-user-box", false)
		else
			Session.set("display-user-box", true)

	'click .notification': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		Meteor.call "notificationsSeen"

		if Session.get("display-notification-box")
			Session.set("display-notification-box", false)
			userNotifications = db.notifications.find({"notificationOwner": Meteor.userId()}, {sort: {"createdAt": -1}})

			userNotifications.forEach (notification) ->
				userNotifications[notification._id] = notification.seen

			notSeenNotifications.set(userNotifications)
		else
			Session.set("display-notification-box", true)

##################################################
Template.userMenuDropdown.events
	'click .logout': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		Meteor.logout()
		FlowRouter.go("/")

	'click .edit-profile': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		Modal.show('editProfileModal')

##################################################
Template.userNotification.helpers
	notificationSeen: () ->
		userNotifications = notSeenNotifications.get()
		unless userNotifications[@_id]?
			return true
		return userNotifications[@_id] == true

	userNotifications: () ->
		return db.notifications.find({"notificationOwner": Meteor.userId()}, {sort: {createdAt: -1}})

	momentToNow: (createdAt) ->
		return moment(createdAt).fromNow()

	badgeStatus: () ->
		type = @type
		switch type
			when "new-user", "password-reset"
				return "success"
			when 'time-registered'
				return "warning"

	revertMessage: () ->
		if @data?.reverted
			return "(Modificado)"
		else if @data?.disabled
			return "(Proyecto Completado)"
		else
			return ""

	notificationDisabled: () ->
		if @data?.reverted or @data?.disabled
			return true
		else
			return false


Template.userNotification.events
	'click .notification-item': (e,t) ->
		e.preventDefault()
		e.stopPropagation()

		unless @data?.reverted or @data?.disabled or @type != 'time-registered'
			Session.set("display-notification-box", false)
			Modal.show('editTimeModal', @)

##################################################
Template.headerNavigation.onCreated () ->
	Session.set("navigation-menu", false)


Template.headerNavigation.helpers
	template: () ->
		FlowRouter.watchPathChange()
		return FlowRouter.current().route.name

	ordenProyectos: () ->
		user = db.users.findOne({_id: Meteor.userId()})
		return user?.settings?.projectSort

	navigationState: () ->
		FlowRouter.watchPathChange()
		currentState = FlowRouter.current().route.name

		if currentState == "projects"
			displayMenu = true
		else
			displayMenu = false

		if currentState == "projects" or currentState=="projectGeneral" or currentState=="projectTimeLog" or currentState=="projectDefectLog" or currentState=="projectSummary" or currentState=="projectScripts" or currentState=="estimatingtemplate"
			initialRoute = "projects"
		else if currentState == "community"
			initialRoute = "help"
		else
			initialRoute = currentState

		Routes = [{
			title: sys.getPageName(initialRoute)
			route: initialRoute
			fid: false
			pid: false
			lastValue: false
			displayMenu: displayMenu
		}]

		if FlowRouter.getParam("fid")
			Routes.push({
				title: "Iteraciones"
				route: "iterations"
				fid: FlowRouter.getParam("fid")
				pid: false
				lastValue: false
				displayMenu: false
			})

		if FlowRouter.getParam("id")
			Project = db.projects.findOne({_id: FlowRouter.getParam("id"), "projectOwner": Meteor.userId()})

			if Project
				Routes.push({
					title: Project.title
					route: "projectGeneral"
					fid: FlowRouter.getParam("fid")
					pid: FlowRouter.getParam("id")
					lastValue: false
					displayMenu: false
				})

		if currentState == "community"
			Routes.push({
				title: "Comunidad"
				route: "community"
				fid: false
				pid: false
				lastValue: true
				displayMenu: false
			})

		_.last(Routes).lastValue = true

		return Routes


Template.headerNavigation.events
	'click .state-menu': (e,t) ->
		currentState = Session.get("navigation-menu")
		Session.set("navigation-menu", !currentState)

	'click .create-project': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		Modal.show('createProjectModal')

	'click .create-iteration': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		currentProject = db.projects.findOne({ _id: FlowRouter.getParam("fid") })

		# The currentProject takes the parent projects levelPSP and gives it to the new interation
		data = {
			title: "Nueva iteración"
			description: "Descripción de esta nueva iteración"
			levelPSP: currentProject.levelPSP
			parentId: FlowRouter.getParam("fid")
		}

		Meteor.call "create_project", data, (error) ->
			if error
				console.warn(error)
				sys.flashStatus("error-create-iteration")
			else
				sys.flashStatus("create-iteration")

	'click .create-question': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		Modal.show('createQuestionModal')

	'click .project-order': (e,t) ->
		e.preventDefault()
		e.stopPropagation()
		value = $(e.target).closest(".project-order").data('value')

		Meteor.call "change_project_sorting_settings", value, (error) ->
			if error
				console.warn(error)
			else
				sys.flashStatus("change-project-sorting")

##################################################