// Databricks notebook source
// MAGIC %md
// MAGIC # Configure Databricks Workspace
// MAGIC 
// MAGIC This notebook will take several steps to configure a newly created Databricks workspace within an Enterprise Scale Analytics landing zone.

// COMMAND ----------

// MAGIC %sh
// MAGIC apt-get -y install maven

// COMMAND ----------

// MAGIC %md
// MAGIC ## Build Application Logging `.jar` Files
// MAGIC 
// MAGIC The [Microsoft Patterns & Practices](https://github.com/mspnp) collection contains a project for [Monitoring Azure Databricks in an Azure Log Analytics Workspace](https://github.com/mspnp/spark-monitoring).
// MAGIC This allows enterprises to centralize storage and analysis of their Spark logs in the Azure Log Analytics service.
// MAGIC 
// MAGIC The following section of the notebook will download the source code for libraries that will send log information to Azure Log Analytics.  Maven will then be used to build the project, and the resulting
// MAGIC `.jar` files will be copied to the DBFS.  From there, clusters in this workspace can load the `.jar` files when they spin up.
// MAGIC 
// MAGIC For the build process, we will need a tool to parse the `pom.xml` file and obtain the build profile names.  We will install the `xmlstarlet` package to accomplish this.

// COMMAND ----------

// MAGIC %sh
// MAGIC apt-get -y install xmlstarlet

// COMMAND ----------

// MAGIC %md
// MAGIC Now we will get the code from GitHub and use Maven to build all of the different profiles defined for the project.

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /usr/app-log-build
// MAGIC cd /usr/app-log-build
// MAGIC 
// MAGIC rm -rf spark-monitoring
// MAGIC git clone https://github.com/mspnp/spark-monitoring.git
// MAGIC cd spark-monitoring/
// MAGIC 
// MAGIC MAVEN_PROFILES=($(xmlstarlet sel -N pom=http://maven.apache.org/POM/4.0.0 -t -v "pom:project/pom:profiles/pom:profile/pom:id" src/pom.xml))
// MAGIC 
// MAGIC for MAVEN_PROFILE in "${MAVEN_PROFILES[@]}"
// MAGIC do
// MAGIC     mvn -f src/pom.xml install -P ${MAVEN_PROFILE}
// MAGIC done

// COMMAND ----------

// MAGIC %md
// MAGIC Now we can copy our freshly built `.jar` files to the DBFS.

// COMMAND ----------

// MAGIC %sh
// MAGIC mkdir -p /dbfs/databricks/spark-monitoring
// MAGIC cp /usr/app-log-build/spark-monitoring/src/target/*.jar /dbfs/databricks/spark-monitoring

// COMMAND ----------

// MAGIC %fs
// MAGIC ls /databricks/spark-monitoring/
