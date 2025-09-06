// In android/build.gradle.kts

allprojects {
    // This block forces a single, stable version of the Google Play libraries
    // for the entire project, resolving the dependency conflict.
    configurations.all {
        resolutionStrategy {
            force("com.google.android.play:core:1.10.3")
            force("com.google.android.gms:play-services-tasks:18.1.0")
        }
    }

    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
