allprojects {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

// === Custom build directory setup ===
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.set(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.set(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")

    // Apply only to the "receive_sharing_intent" module
    if (name == "receive_sharing_intent") {

        // Apply Java 17 compile options if Android plugin is present
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileOptions.sourceCompatibility = JavaVersion.VERSION_1_8
            compileOptions.targetCompatibility = JavaVersion.VERSION_1_8
        }

        // Apply Kotlin JVM target 17
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions.jvmTarget = JavaVersion.VERSION_1_8.toString()
        }
    }

}

// === Clean task ===
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
