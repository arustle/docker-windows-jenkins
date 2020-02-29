import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.plugins.credentials.domains.*
import com.cloudbees.jenkins.plugins.sshcredentials.impl.*
import hudson.plugins.sshslaves.*


println("Setting credentials")

def domain = Domain.global()
def store = Jenkins.instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()


def credentials=[
    'scope': CredentialsScope.GLOBAL,
    'id': 'JENKINS_CREDENTIALS_FOR_THIS_REPO',
    'username':'JENKINS_CREDENTIALS_FOR_THIS_REPO', 
    'privateKeySource': new BasicSSHUserPrivateKey.DirectEntryPrivateKeySource(""),
    'passphrase': '',
    'description':''
];

def user = new BasicSSHUserPrivateKey(credentials.scope, credentials.id, credentials.username, credentials.privateKeySource, credentials.passphrase, credentials.description)

store.addCredentials(domain, user)