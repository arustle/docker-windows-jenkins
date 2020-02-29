import jenkins.model.Jenkins
import org.jenkinsci.plugins.workflow.job.WorkflowJob

import org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition
import hudson.plugins.git.GitSCM
import hudson.plugins.git.BranchSpec

println("Creating jobs")


WorkflowJob job = Jenkins.instance.createProject(WorkflowJob, 'JOB NAME')

def definition = new CpsScmFlowDefinition(new GitSCM('GIT_REPO'), 'Jenkinsfile')
definition.scm.userRemoteConfigs[0].credentialsId = 'JENKINS_CREDENTIALS_FOR_THIS_REPO'
definition.scm.branches = [ new BranchSpec("*/master") ]

job.definition = definition
