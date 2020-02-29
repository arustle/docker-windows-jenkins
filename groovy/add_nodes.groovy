import jenkins.model.Jenkins
import hudson.model.*
import hudson.slaves.*

Slave agent = new DumbSlave(
    "AGENT_NAME",  // Agent name, usually matches the host computer's machine name
    "", // Agent description
    "", // Workspace on the agent's computer
    "1",// Number of executors
    Node.Mode.EXCLUSIVE, // "Usage" field, EXCLUSIVE is "only tied to node", NORMAL is "any"
    "", // Labels
    new JNLPLauncher(), // Launch strategy, JNLP is the Java Web Start setting services use
    RetentionStrategy.INSTANCE // Is the "Availability" field and INSTANCE means "Always"
)

Jenkins.instance.addNode(agent)

