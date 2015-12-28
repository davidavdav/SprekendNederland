## some quick plots...

mysql <- function(cmd)
    sprintf('mysql sn -NB -e "%s"', cmd)

## distribution of the nummer of recordings per speaker
speaker.recording <- function() {
    cmd <- mysql("select profile_id, count(*) as count from recordings group by profile_id")
    x <- read.table(pipe(cmd), header=F, col.names=c("pid", "nrec"))
    breaks <- 0:100
    xx <- subset(x, nrec <= breaks[length(breaks)])
    h <- hist(xx$nrec, breaks=breaks, freq=T)
    plot(h, main="Histogram of number of recordings per speaker", xlab="number of recordings")
    x
}

## distribution of the number of answers per listener
listener.answer <- function() {
    cmd <- mysql("select profile_id, count(*) from answers group by profile_id")
    x <- read.table(pipe(cmd), header=F, col.names=c("pid", "nans"))
    breaks <- seq(0, 500, by=5)
    xx <- subset(x, nans <= breaks[length(breaks)])
    h <- hist(xx$nans, breaks=breaks, freq=T)
    plot(h, main="Histogram of number of answers per listener", xlab="number of answers")
    x
}

## distribution of the number of answers per speaker, as a function of speaker number (enrollment time)
speaker.answer <- function() {
    cmd <- mysql("select tasks.question_id, recordings.profile_id as speakerid, answers.profile_id as subjectid, answers.answer_numeric from tasks join answers, recordings where answers.id=tasks.answer_id and tasks.question_recording_id=recordings.id and answers.answer_numeric is not null")
    x <- read.table(pipe(cmd), header=F, col.names=c("qid", "sid", "lid", "value"))
    x
}
                 

## computes how many Frans Hinskens sentences/words are completed
sent1.byspeaker <- function(words=F) {
    group <- 1 + words
    cmd <- mysql(sprintf("select recordings.profile_id, count(*) from tasks join recordings, task_text, texts where recording_id is not null and tasks.id=task_text.task_id and task_text.text_id=texts.id and texts.text_group_id=%d and recordings.id=tasks.recording_id group by recordings.profile_id", group))
    x <- read.table(pipe(cmd), header=F, col.names=c("pid", "n"), )
    title <- sprintf("Number of List1 %ss completed", ifelse(words, "word", "sentence"))
    hist(x$n, main=title, xlab="n")
    x
}

speed <- function(what="answers") {
    x <- read.table(pipe(mysql(sprintf("select created_at at from %s", what))), header=F, col.names=c("date", "time"), stringsAsFactors=F)
    x$date <- as.POSIXlt(paste(x$date, x$time), format="%Y-%m-%d %H:%M:%S")
    d <- density(as.numeric(x$date), 1000, n=2^11)
    d$date <- as.POSIXlt(as.character(d$x), format="%s")
    plot(d$date, d$y * d$n, main=paste("Rate of receiving", what), type="l", lwd=2, xlab="date", ylab="entries / second")
    x
}

speed.daily <- function(x, what="answers") {
    ndays <- floor(as.numeric(x$date[nrow(x)] - x$date[1]))
    time <- as.numeric(strptime(paste("01-01-1970", x$time), format="%d-%m-%Y %H:%M:%S"))
    d <- density(time, 100, n=2^11)
    d$time <- as.POSIXlt(as.character(d$x), format="%s")
    plot(d$time, d$y * d$n / ndays, main=paste("Average daily rate of receiving", what), type="l", lwd=2, xlab="time", ylab="entries / second")
}

age <- function() {
    x <- read.table(pipe(mysql("select answers.profile_id, answers.answer_numeric from tasks join answers where tasks.answer_id=answers.id and tasks.question_id=5")), header=F, col.names=c("pid", "year"))
    x
}

library(ggplot2)
library(ggmap)
map <-function() {
    x <- read.table("66.txt", header=T)
    map <- get_map(location = "Netherlands", zoom=7)
    ggmap(map) + geom_point(data=x, aes(x=slong, y=slat), size=2)
}    

## test
janee <- function() {
    x <- read.table(pipe(mysql("select options.value FROM options, tasks INNER JOIN answers ON answers.id = tasks.answer_id INNER JOIN answer_option ON answers.id = answer_option.answer_id  WHERE tasks.question_id = 79 AND answer_option.option_id = options.id")))
    x
}

value.questions <- paste("q", 53:74, sep="")
read.answers <- function(file="answers.csv") {
    x <- read.csv("answers.csv", header=T)
    x$qtype <- factor(x$qtype, levels=c("describe", "words", "sentence", "speech"),
                      ordered=T, labels=c("picture", "words", "sentence", "spontaneous"))
    x
}

value.answers <- function(x) {
    x <- droplevels(subset(x, qid %in% value.questions))
    x$value <- as.numeric(as.character(x$value))
    x
}
    

## work with entries with a minimum of answers
select.answers <- function(x, crit="sid", min=30) {
    sel <- table(x[[crit]]) >= min
    n <- names(sel)[sel]
    x[x[[crit]] %in% n,]
}

renorm.answers <- function(x) {
    m <- aggregate(value ~ sid, x, mean)
    row.names(m) <- m$sid
    s <- aggregate(value ~ sid, x, sd)
    row.names(s) <- s$sid
    s$value <- pmax(0.1, s$value)
    sid <- as.character(x$sid)
    x$value <- (x$value - m[sid,]$value) / s[sid,]$value
    x
}
