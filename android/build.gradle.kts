import org.gradle.api.tasks.Delete
import com.android.build.gradle.BaseExtension
import org.gradle.api.file.Directory

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Move build directories outside of module folders (optional)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    afterEvaluate {
        extensions.findByType<BaseExtension>()?.apply {
            // Enforce global NDK version
            ndkVersion = "27.0.12077973"

            // ✅ Namespace fix for flutter_file_dialog
            if (project.name == "flutter_file_dialog" && namespace == null) {
                namespace = "com.alexmercerind.flutter_file_dialog"
                println("✅ Namespace set for $project.name")
            }
        }
    }
}

// Uncomment and adjust clean task if needed
// tasks.register<Delete>("clean") {
//     delete(rootProject.layout.buildDirectory)
// }
