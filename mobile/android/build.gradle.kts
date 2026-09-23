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
// بعض الإضافات (file_picker و share_plus) ما زالت تُصرَّف مقابل API 34،
// بينما تتطلّب تبعياتها 36 فأعلى. نفرض compileSdk موحّدًا على كل المشاريع
// الفرعية. يجب تسجيل هذا قبل evaluationDependsOn أدناه، وإلّا يفوت الأوان
// على afterEvaluate لأن المشاريع تكون قد قُيّمت بالفعل.
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.BaseExtension) {
                ext.compileSdkVersion(36)
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
