// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

// Register stimulus-rails-nested-form
import NestedForm from "stimulus-rails-nested-form"
application.register("nested-form", NestedForm)
