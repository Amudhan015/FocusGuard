allprojects {
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

// Plugin packages such as file_picker ship their own build.gradle, pinned
// to whatever compileSdk they were published against (currently 34).
// android/app/build.gradle.kts's `compileSdk = 36` only applies to the
// :app module itself, not to these library subprojects, which is why the
// AAR-metadata check ("flutter_plugin_android_lifecycle requires
// compiling against API 36") kept failing even after that edit.
//
// A plain `compileSdk = 36` assignment here (inside plugins.withId) is
// NOT enough on its own: it fires as soon as com.android.library is
// applied, which is near the top of file_picker's own build.gradle - but
// that script then goes on to explicitly set `compileSdkVersion 34`
// itself a few lines later, in the SAME script, which silently
// overwrites our 36 back down to 34. finalizeDsl is AGP's hook for
// exactly this situation: it runs after the module's own build script has
// finished configuring the android {} block, so whatever we set here is
// guaranteed to be the last word, not an early one that gets clobbered.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl { extension ->
                if (extension.compileSdk == null || extension.compileSdk!! < 36) {
                    extension.compileSdk = 36
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
