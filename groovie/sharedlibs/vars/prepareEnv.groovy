def String call() {
    MAX_MSG_LEN = 100
    def changeString = ""
    def changeAuthor = ""
    def changeLogSets = currentBuild.changeSets
    for (int i = 0; i < changeLogSets.size(); i++) {
        def entries = changeLogSets[i].items
        for (int j = 0; j < entries.length; j++) {
            def entry = entries[j]
            truncated_msg = entry.msg.take(MAX_MSG_LEN)
            changeString += " - ${truncated_msg} [${entry.author}]\n"
            changeAuthor = "${entry.author}"
        }
    }
    if (!changeString) {
        changeString = " - No new changes"
    }
    println changeString
    return changeAuthor
}