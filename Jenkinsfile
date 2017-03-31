#!/usr/bin/env groovy
import com.cloudbees.groovy.cps.NonCPS
import org.yaml.snakeyaml.Yaml

node('master') {
    def git_branch = env.BRANCH
    def fork = env.FORK
    def git_url = "https://github.com/${fork}/presto"
    def stages = env.STAGES

    echo "git_branch: " + git_branch
    echo "git_url: " + git_url
    echo "stages: " + stages

    def user = ""
    wrap([$class: 'BuildUser']) {
        user = env.BUILD_USER_ID
    }
    currentBuild.description = "User: " + user + "\nFork: " + fork + "\nBranch: " + branch + "\nStages: " + stages

    sh 'git init'
    sh "git fetch --prune --tags --progress ${git_url} +refs/heads/*:refs/remotes/${fork}/*"
    def revision = sh returnStdout: true, script: "git rev-parse refs/remotes/${fork}/${branch}"
    echo "Revision: ${revision}"
    currentBuild.description = currentBuild.description + "\nRevision: " + revision
    sh "git checkout -f ${revision}"

    def yaml_content = readFile '.travis.yml'
    def travis = readAndConvertTravis(yaml_content)
    def global = travis.env.global
    def matrix = travis.env.matrix
    def combine = combineEnvironmentVariables(global, matrix)
    def install_scripts = getYamlStringOrListAsList(travis.install)
    def scripts = getYamlStringOrListAsList(travis.script)

    echo "global: " + global.toString()
    echo "matrix: " + matrix.toString()
    echo "combine: " + combine.toString()
    echo "install_scripts: " + install_scripts.toString()
    echo "scripts: " + scripts.toString()

    def failed = false

    def parallelInvocations = [:]
    def stash_names = []
    for (int i = 0; i < combine.size(); i++) {
        def combined_variables = combine.get(i)
        def name = matrix.get(i).toString()
        if (stages.equals('ALL') || stages.contains(name)) {
            parallelInvocations[name] = {
                node('worker') {
                    timeout(time: 2, unit: 'HOURS') {

                        sh "git init"
                        sh "git fetch --prune --tags --progress ${git_url} +refs/heads/*:refs/remotes/${fork}/*"
                        sh "git checkout -f ${revision}"

                        configFileProvider([configFile(fileId: '00c4e7c0-a280-47b5-935e-9ed912f12d1c', variable: 'SETTINGS_XML_LOCATION')]) {
                            def settings_xml_location = env.SETTINGS_XML_LOCATION
                            echo "settings_xml_location: " + settings_xml_location
                            def maven_config = 'MAVEN_CONFIG="--settings ' + settings_xml_location + '"'
                            echo "maven_config: " + maven_config
                            echo "combined_variables: " + combined_variables
                            def env_string = combined_variables + " " + maven_config
                            echo "env_string: " + env_string

                            sh 'sudo rm -rf ./*/target'
                            sh './mvnw clean'
                            sh 'for container in $(docker ps -a -q); do docker rm -f ${container}; done'
                            for (int j = 0; j < install_scripts.size(); j++) {
                                sh env_string + '\n' + install_scripts.get(j).toString()
                            }
                            for (int j = 0; j < scripts.size(); j++) {
                                try {
                                    sh env_string + '\n' + scripts.get(j).toString()
                                }
                                // Handle user interrupt
                                // https://gist.github.com/stephansnyt/3ad161eaa6185849872c3c9fce43ca81
                                catch (org.jenkinsci.plugins.workflow.steps.FlowInterruptedException fie) {
                                    // this ambiguous condition means a user probably aborted
                                    if (fie.causes.size() == 0) {
                                        throw fie
                                    }
                                    else {
                                        failed = true
                                    }
                                }
                                catch (hudson.AbortException ae) {
                                    // this ambiguous condition means during a shell step, user probably aborted
                                    if (ae.getMessage().contains('script returned exit code 143')) {
                                        throw ae
                                    }
                                    else {
                                        failed = true
                                    }
                                }
                                catch (ignored) {
                                    failed = true
                                }
                            }
                            def status = sh returnStatus: true, script: 'ls **/target/*-reports/testng-results.xml'
                            if (status == 0) {
                                def stash_name = UUID.randomUUID().toString()
                                echo "Stashing: ${stash_name}"
                                stash includes: '**/target/*-reports/testng-results.xml', name: stash_name
                                stash_names.add(stash_name)
                            }
                        }
                    }
                }
            }
        }
    }

    if (parallelInvocations.size() == 0) {
        error 'no stages selected'
    }

    stage("Parallel Travis Execution") {
        echo "Starting parallel execution"
        parallel parallelInvocations
        echo "Parallel execution has been finished"
        sh 'rm -rf ./*/target'
        for (int i = 0; i < stash_names.size(); i++) {
            def stash_name = stash_names.get(i)
            echo "Unstashing: ${stash_name}"
            unstash stash_name
        }
        step([$class: 'Publisher', reportFilenamePattern: '**/target/*-reports/testng-results.xml'])
        if (failed && currentBuild.result != 'UNSTABLE') {
            currentBuild.result = 'FAILURE'
        }
    }
}

def getYamlStringOrListAsList(yamlEntry)
{
    if (yamlEntry == null) {
        return []
    }
    else if (yamlEntry instanceof String) {
        return [yamlEntry]
    }
    else if (yamlEntry instanceof ArrayList) {
        return yamlEntry
    }
    else {
        return ""
    }
}

def combineEnvironmentVariables(global, matrix)
{
    def grobal_env_string = ""
    for (int i = 0; i < global.size(); i++) {
        if (grobal_env_string.length() > 0) {
            grobal_env_string += " "
        }
        grobal_env_string += global.get(i)
    }

    def result = []
    for (int i = 0; i < matrix.size(); i++) {
        result[i] = grobal_env_string + (grobal_env_string.length() > 0 ? " " : "") + matrix.get(i)
    }
    return result
}

@NonCPS
def readAndConvertTravis(String travisYml)
{
    Yaml yaml = new Yaml()
    Map<String, Object> travisYaml = (Map<String, Object>) yaml.load(travisYml)
    return travisYaml
}

