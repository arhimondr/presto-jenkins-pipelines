#!/usr/bin/env groovy

import org.yaml.snakeyaml.Yaml
import com.cloudbees.groovy.cps.NonCPS

node('master') {
    def git_branch = env.BRANCH
    def fork = env.FORK
    def git_url = "https://github.com/${fork}/presto"
    def stages = env.STAGES
     
    echo "git_branch: " + git_branch; 
    echo "git_url: " + git_url; 
    echo "stages: " + stages;

    wrap([$class: 'BuildUser']) {
    	def user = env.BUILD_USER_ID
	currentBuild.description = "User: " + user + "\nFork: " + fork + "\nBranch: " + branch + "\nStages: " + stages 
    }
    
    git branch: git_branch, url: git_url
    def yaml_content = readFile '.travis.yml'
    def travis = readAndConvertTravis(yaml_content)
    def global = [] // travis.env.global;
    def matrix = travis.env.matrix;
    def combine = combineEnvironmentProperties(matrix, global);
    def install_script = travis.install;
    def scripts = travis.script
   
    echo "global: " + global.toString();
    echo "matrix: " + matrix.toString();
    echo "combine: " + combine.toString();
    echo "install_script: " + combine.toString();
    echo "scripts: " + scripts.toString();
    
    def parallelInvocations = [:]
    for(int i=0; i<combine.size(); i++){
        def env = combine.get(i)
	def name = env.toString()
        if(stages.equals('ALL') || stages.contains(name)){
            parallelInvocations[name] = {
                node('worker') {
                    git branch: git_branch, url: git_url
                    withEnv(env) {
			sh './mvnw clean'
			sh 'for container in $(docker ps -a -q); do docker rm -f ${container}; done'
                        sh install_script
                        for(int j=0; j<scripts.size(); j++){
                            sh scripts.get(j)
                        }
                    }
                }
            }
        }
    }

    if(parallelInvocations.size()==0){
        error 'no stages selected'
    }
    
    stage("Parallel Travis Execution") {
        parallel parallelInvocations
    }
}

def combineEnvironmentProperties(matrix, global){
    def result = [];
    for(int i=0; i<matrix.size(); i++){
        def properties = [];
        properties.addAll(global);
        properties.add(matrix.get(i));
        result[i] = properties;
    }
    return result;
}

@NonCPS
def readAndConvertTravis(String travisYml) {
    Yaml yaml = new Yaml()
    Map<String, Object> travisYaml = (Map<String, Object>) yaml.load(travisYml)
    return travisYaml
}

