package com.github.jmodel.validator.plugin.jvmmodel

import com.github.jmodel.validator.plugin.util.Util
import com.github.jmodel.validator.plugin.validationlanguage.Block
import com.github.jmodel.validator.plugin.validationlanguage.Precondition
import com.github.jmodel.validator.plugin.validationlanguage.Service
import com.github.jmodel.validator.plugin.validationlanguage.SingleFieldPath
import com.github.jmodel.validator.plugin.validationlanguage.Validation
import com.github.jmodel.validator.plugin.validationlanguage.Variable
import com.google.inject.Inject
import java.util.Map
import org.eclipse.xtext.common.types.JvmDeclaredType
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder

/**
 * <p>Infers a JVM model from the source model.</p> 
 * 
 * <p>The JVM model should contain all elements that would appear in the Java code 
 * which is generated from the source model. Other models link against the JVM model rather than the source model.</p>     
 */
class ValidationLanguageJvmModelInferrer extends AbstractModelInferrer {

	/**
	 * convenience API to build and initialize JVM types and their members.
	 */
	@Inject extension JvmTypesBuilder

	/**
	 * The dispatch method {@code infer} is called for each instance of the
	 * given element's type that is contained in a resource.
	 * 
	 * @param element
	 *            the model to create one or more
	 *            {@link JvmDeclaredType declared
	 *            types} from.
	 * @param acceptor
	 *            each created
	 *            {@link JvmDeclaredType type}
	 *            without a container should be passed to the acceptor in order
	 *            get attached to the current resource. The acceptor's
	 *            {@link IJvmDeclaredTypeAcceptor#accept(org.eclipse.xtext.common.types.JvmDeclaredType)
	 *            accept(..)} method takes the constructed empty type for the
	 *            pre-indexing phase. This one is further initialized in the
	 *            indexing phase using the closure you pass to the returned
	 *            {@link IPostIndexingInitializing#initializeLater(org.eclipse.xtext.xbase.lib.Procedures.Procedure1)
	 *            initializeLater(..)}.
	 * @param isPreIndexingPhase
	 *            whether the method is called in a pre-indexing phase, i.e.
	 *            when the global index is not yet fully updated. You must not
	 *            rely on linking using the index if isPreIndexingPhase is
	 *            <code>true</code>.
	 */
	def dispatch void infer(Validation element, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {

		val _VALIDATION = "com.github.jmodel.validator.api.domain.Validation"
		val _VALIDATION_RESULT = "com.github.jmodel.validator.Result"
		val _MODEL = "com.github.jmodel.api.domain.Model"
		val _MODEL_EXCEPTION = "com.github.jmodel.ModelException"

		acceptor.accept(element.toClass(element.name)) [

			if (element.superType === null) {
				superTypes += typeRef(_VALIDATION)
			} else {
				superTypes += typeRef(element.superType.name)
			}

			members += element.toField("instance", typeRef(_VALIDATION)) [
				static = true
			]

			members += element.toConstructor() [
				visibility = JvmVisibility.PRIVATE
			]

			members += element.toMethod("getInstance", typeRef(_VALIDATION)) [
				static = true
				synchronized = true

				body = [
					append('''
						if (instance == null) {
							instance = new «element.name»();
							
							instance.init(instance);
						}	
						
						return instance;
					''')
				]

			]

			members += element.toMethod("init", typeRef(void)) [
				parameters += element.toParameter("myInstance", typeRef(_VALIDATION))
				annotations += annotationRef("java.lang.Override")
				body = [
					append('''
						super.init(myInstance);
						«element.genCommonSetting»
						«element.genOriginalPaths»
					''')
				]
			]

			members += element.toMethod("execute", typeRef(void)) [
				parameters += element.toParameter("model", typeRef(_MODEL))
				parameters += element.toParameter("serviceArgsMap", typeRef(Map))
				parameters += element.toParameter("myVariablesMap", typeRef(Map))
				parameters += element.toParameter("result", typeRef(_VALIDATION_RESULT))
				exceptions += typeRef(_MODEL_EXCEPTION)
				annotations += annotationRef("java.lang.Override")
				body = element.body
			]

		]
	}

	def genCommonSetting(Validation element) '''
		«IF element.source.name.literal== 'JSON'»								
			myInstance.setFormat(com.github.jmodel.api.format.FormatEnum.JSON);														
		«ELSEIF element.source.name.literal== 'XML'» 
			myInstance.setFormat(com.github.jmodel.api.format.FormatEnum.XML);	
		«ELSEIF element.source.name.literal== 'BEAN'» 
			myInstance.setFormat(com.github.jmodel.api.format.FormatEnum.BEAN);	
		«ENDIF»
		
		com.github.jmodel.api.domain.Entity rootModel = new com.github.jmodel.api.domain.Entity();
		myInstance.setTemplateModel(rootModel);
		
		«FOR service : element.eAllContents.toIterable.filter(typeof(Service))»
			myInstance.getServiceList().add("«service.serviceName»");
		«ENDFOR»
					
	'''

	def genOriginalPaths(Validation element) '''
		
		«FOR variable : element.eAllContents.toIterable.filter(typeof(Variable))»
			myInstance.getRawVariables().add("«Util.getVariableName(variable.expression)»");
		«ENDFOR»
		
		«FOR block : element.eAllContents.toIterable.filter(typeof(Block))»
			myInstance.getRawFieldPaths().add("«Util.getFullModelPath(block)»._");
			
				«FOR field : block.eAllContents.toIterable.filter(typeof(SingleFieldPath))»
					«IF field.absolutePath!==null»
						myInstance.getRawFieldPaths().add("«Util.getSourceModelPathByPath(field)».«field.content»");
					«ELSE»
						myInstance.getRawFieldPaths().add("«Util.getFullModelPath(field)».«field.content»");
					«ENDIF»		
				«ENDFOR»
			«ENDFOR»
		
			«FOR precondition : element.eAllContents.toIterable.filter(typeof(Precondition))»
				«FOR field : precondition.eAllContents.toIterable.filter(typeof(SingleFieldPath))»
					myInstance.getRawFieldPaths().add("«field.content»");
				«ENDFOR»
			«ENDFOR»		
	'''
}
