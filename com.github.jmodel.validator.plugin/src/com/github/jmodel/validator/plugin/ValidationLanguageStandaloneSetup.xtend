/*
 * generated by Xtext 2.12.0
 */
package com.github.jmodel.validator.plugin


/**
 * Initialization support for running Xtext languages without Equinox extension registry.
 */
class ValidationLanguageStandaloneSetup extends ValidationLanguageStandaloneSetupGenerated {

	def static void doSetup() {
		new ValidationLanguageStandaloneSetup().createInjectorAndDoEMFRegistration()
	}
}
