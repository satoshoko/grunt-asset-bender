_ = require 'underscore'
Q = require 'q'
path = require 'path'
fs = require 'fs'

module.exports = (grunt) ->
    utils = require('../lib/utils').init(grunt)
    LegacyAssetBenderRunner = require('../lib/legacy_asset_bender_runner').init(grunt)

    grunt.registerTask 'bender_run_jasmine_tests', 'Runs the jasmine tests if any exist for this project. Stops any further tasks if the tests fail', ->
        done = @async()

        grunt.config.requires 'bender.build.projectName',
                              'bender.build.copiedProjectDir',
                              'bender.build.archiveDir',
                              'bender.build.versionWithStaticPrefix'

        projectDir = grunt.config.get 'bender.build.copiedProjectDir'
        stopwatch  = utils.graphiteStopwatch(grunt)

        hasSpecs = fs.existsSync path.join projectDir, '/static/test/specs.js'
        runJasmineTests = utils.envVarEnabled('RUN_JASMINE_TESTS', true)

        runTestOn = utils.preferredModeBuilt()

        if hasSpecs and (runJasmineTests == '0' or runJasmineTests == 'false')
            grunt.log.writeln "Skipping jasmine tests since RUN_JASMINE_TESTS=#{runJasmineTests}\n"
            done()

        else if hasSpecs
            grunt.log.writeln "Running jasmine tests\n"

            buildVersions = {}
            buildVersions[grunt.config.get 'bender.build.projectName'] = grunt.config.get 'bender.build.versionWithStaticPrefix'

            runner = new LegacyAssetBenderRunner _.extend {},
                project: projectDir
                destDir:  grunt.config.get 'bender.build.#{runTestsOn}.outputDir'
                archiveDir: grunt.config.get 'bender.build.archiveDir'
                mode: 'precompiled'
                command: 'jasmine'
                headless: true
                buildVersions: buildVersions

            stopwatch.start 'jasmine_test_duration'

            runner.run().done ->
                grunt.log.writeln 'Jasmine tests succeeded.'
                done()
            .fail ->
                stopwatch.stop 'jasmine_test_duration'
                done new Error 'Jasmine tests failed, failing build.'

        else
            grunt.log.writeln "No jasmine tests to run"
            done()

