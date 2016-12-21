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
    def combine = combineEnvironmentProperties(matrix, global)
    def install_scripts = getYamlStringOrListAsList(travis.install)
    def scripts = getYamlStringOrListAsList(travis.script)

    echo "global: " + global.toString()
    echo "matrix: " + matrix.toString()
    echo "combine: " + combine.toString()
    echo "install_scripts: " + install_scripts.toString()
    echo "scripts: " + scripts.toString()

    def build = {}
    build.state = 'SUCCESS'

    def parallelInvocations = [:]
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
                            def maven_config = 'MAVEN_CONFIG=--settings ' + settings_xml_location
                            echo "maven_config: " + maven_config
                            def invocation_environment = []
                            invocation_environment.addAll(combined_variables)
                            invocation_environment.add(maven_config)
                            withEnv(invocation_environment) {
                                sh 'sudo rm -rf ./*/target'
                                sh './mvnw clean'
                                sh 'for container in $(docker ps -a -q); do docker rm -f ${container}; done'
                                try {
                                    for (int j = 0; j < install_scripts.size(); j++) {
                                        sh install_scripts.get(j).toString()
                                    }
                                    for (int j = 0; j < scripts.size(); j++) {
                                        sh scripts.get(j).toString()
                                    }
                                    step([$class: 'Publisher', reportFilenamePattern: '**/target/*-reports/testng-results.xml'])
                                }
                                catch (err) {
                                    step([$class: 'Publisher', reportFilenamePattern: '**/target/*-reports/testng-results.xml'])
                                    transitionToState(build, currentBuild.result)
                                    if (currentBuild.result != 'UNSTABLE') {
                                        throw err
                                    }
                                }
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
        echo "Starting paralel execution"
        parallel parallelInvocations
        echo "Paralel execution has finished. State is: ${build.state}"
        currentBuild.result = build.state
    }
}

def transitionToState(build, state)
{
    echo "Transitioning from ${build.state} to ${state}"
    // transition to FAILED immediately
    if (state == 'FAILURE') {
        build.state = state
        echo "Transitioned to ${state}"
    }
    // transition to UNSTABLE only if it is still SUCCESS
    if (state == 'UNSTABLE' && build.state == 'SUCCESS') {
        build.state = state
        echo "Transitioned to ${state}"
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

def combineEnvironmentProperties(matrix, global)
{
    def excluded = ['MAVEN_OPTS']

    def globalSanitized = []
    for (int i = 0; i < global.size(); i++) {
        def parsed = parseVariable(global.get(i))
        def key = parsed['key']
        if (!excluded.contains(key)) {
            globalSanitized.add(sanitizeEnvironmentVariable(parsed))
        }
    }

    def result = []
    for (int i = 0; i < matrix.size(); i++) {
        def properties = []
        properties.addAll(globalSanitized)
        properties.add(sanitizeEnvironmentVariable(parseVariable(matrix.get(i))))
        result[i] = properties
    }
    return result
}

def parseVariable(String variable)
{
    def separatorIndex = variable.indexOf('=')
    def parsed = [:]
    parsed['key'] = variable.substring(0, separatorIndex)
    parsed['value'] = variable.substring(separatorIndex + 1, variable.length())
    return parsed
}

def sanitizeEnvironmentVariable(variable)
{
    return stripLeadingTrailingQuotes(variable['key']) + '=' + stripLeadingTrailingQuotes(variable['value'])
}

def stripLeadingTrailingQuotes(String inputString)
{
    if ((inputString.startsWith('"') && inputString.endsWith('"')) || (inputString.startsWith("'") && inputString.endsWith("'"))) {
        return inputString.substring(1, inputString.length() - 1)
    }
    else {
        return inputString
    }
}

@NonCPS
def readAndConvertTravis(String travisYml)
{
    Yaml yaml = new Yaml()
    Map<String, Object> travisYaml = (Map<String, Object>) yaml.load(travisYml)
    return travisYaml
}

