## some quick plots...

## metadata with ordered level of education
read.meta <- function() {
    m <- read.csv("tables/meta-nodistort.csv")
    q33levels <- read.csv("q33.levels", header=F, stringsAsFactors=F)[[1]]
    m$q33 <- ordered(m$q33, levels=q33levels)
    m
}

mysql <- function(cmd)
    sprintf('mysql sn -NB -e "%s"', cmd)

participants.date <- function() {
    x <- read.table(pipe(mysql("select id, created_at from profiles")), header=F, col.names=c("pid", "date", "time"), stringsAsFactors=F)
    x$datetime <- as.POSIXlt(paste(x$date, x$time), format="%Y-%m-%d %H:%M:%S")
    x$date = as.Date(x$date)
    x
}

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

speed <- function(what="answers", makeplot=T) {
    x <- read.table(pipe(mysql(sprintf("select created_at at from %s", what))), header=F, col.names=c("date", "time"), stringsAsFactors=F)
    x$datetime <- as.POSIXlt(paste(x$date, x$time), format="%Y-%m-%d %H:%M:%S")
#    d <- density(as.numeric(x$datetime), 1000, n=2^11)
#    d$date <- as.POSIXlt(as.character(d$x), format="%s")
#    plot(d$date, d$y * d$n, main=paste("Rate of receiving", what), type="l", lwd=2, xlab="date", ylab="entries / second")
    t <- data.frame(table(x$date))
    t <- t[-nrow(t),] ## last day contains incomplete information
    names(t) <- c("date", "n")
    t$date <- as.Date(as.character(t$date))
    t$speed <- t$n / (24*60)
    main <- paste("Rate of receiving", what)
    ylab <- paste(what, "/ minute")
    if (makeplot)
        plot(speed ~ date, t, type="h", lwd=3, main=main, ylab=ylab)
    t
}

## 3: 2 dec 2015, 50: 18 jan 2016
speed.log <- function(what="recordings", first=3, last=50) {
    t <- speed(what, makeplot=F)
    main <- paste("Rate of receiving", what)
    ylab <- paste(what, "/ minute")
    plot(speed ~ date, t, log="y", type="b", lwd=2, main=main, ylab=ylab)
    m <- lm(log(speed, 10) ~ date, t, subset=first:last)
    abline(m, col="blue")
    m
}

speed.daily <- function(x, what="answers") {
    ndays <- floor(as.numeric(x$date[nrow(x)] - x$date[1]))
    time <- as.numeric(strptime(paste("01-01-1970", x$time), format="%d-%m-%Y %H:%M:%S"))
    d <- density(time, 100, n=2^11)
    d$time <- as.POSIXlt(as.character(d$x), format="%s")
    plot(d$time, d$y * d$n / ndays, main=paste("Average daily rate of receiving", what), type="l", lwd=2, xlab="time", ylab="entries / second")
}

plot.age <- function() {
    x <- read.table(pipe(mysql("select answers.profile_id, answers.answer_numeric from tasks join answers where tasks.answer_id=answers.id and tasks.question_id=5")), header=F, col.names=c("pid", "year"))
    x$age <- 2016 - x$year
    hist(x$age, breaks=seq(0, 120, by=5), col=grey(0.8), xlim=c(0,100), main="Histogram of age", xlab="participant's age")
    x
}

library(ggplot2)
library(ggmap)
if (!"map_nl" %in% ls())
    map_nl <- get_map(location="Netherlands", zoom=7)
map <-function() {
    x <- read.csv("tables/meta.csv")
    loc <- splitlocation(x$q04)
    ##    map <- get_map(location = c(left=3, right=7.5, bottom=50.5, top=54), source="osm")
    palette(heat.colors(21))
    ggmap(map_nl) +
        geom_point(data=loc, aes(x=long, y=lat), size=0.5, col="purple", alpha=0.5) +
        geom_density2d(data=loc, aes(x=long, y=lat), size=0.5, col="red") +
            stat_density2d(data=loc, aes(x=long, y=lat, fill=..level.., alpha=..level..), size=0.1, geom="polygon") +
                scale_fill_gradient(low = "green", high = "red") +
                    scale_alpha(range = c(0, 0.3))
}



hetro <- function() {
    x <- read.table("66.txt", header=T)
    plot(table(x$value, x$ssex==x$lsex), main="Love partner and gender", xlab="Value", ylab="same sex", col=c("blue", "pink"))
}

## test
janee <- function() {
    x <- read.table(pipe(mysql("select options.value FROM options, tasks INNER JOIN answers ON answers.id = tasks.answer_id INNER JOIN answer_option ON answers.id = answer_option.answer_id  WHERE tasks.question_id = 79 AND answer_option.option_id = options.id")))
    x
}

value.questions <- paste("q", 53:74, sep="")
read.answers <- function(file="answers.csv") {
    x <- read.csv(file, header=T)
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

splitlocation <- function(x) {
    coords <- data.frame(do.call(rbind, lapply(strsplit(as.character(x), "/"), as.numeric)))
    names(coords) <- c("long", "lat", "zoom")
    coords
}

## analysis using tmap
library(tmap)
library(sp)
data(NLD_prov, NLD_muni)
## style="quantile", n=10, convert2density=T
plot.tmap <- function(region=NLD_prov, ...) {
    m <- read.csv("tables/meta.csv")
    P4S.latlon <- CRS("+proj=longlat +datum=WGS84")
    loc <- SpatialPoints(splitlocation(m$q04[!is.na(m$q04)]), proj4string=P4S.latlon)
    locp <- spTransform(loc, region@proj4string)
    a <- aggregate(count ~ name, transform(over(locp, region), count=1), sum)
    a <- merge(region@data, a, by="name", all.x=T)
    region@data <- a[order(a$code),]
    g <- tm_shape(region) +
        tm_fill("count", title="Sprekend Nederland participation", ...) +
        tm_borders() + tm_layout(frame=F, outer.margins=c(0,0,0,0))
    print(g)
    region
}

extract.martijn.wieling <- function(a=read.csv("tables/answers.csv"), m=read.csv("tables/meta.csv"),
                                    export=FALSE) {
    mm <- data.frame(m$pid, m$q07, splitlocation(m$q04)[,-3])
    x <- subset(a, qid=="q81", c("sid", "lid", "value", "prompt"))
    xx <- subset(a, qid=="q82", c("sid", "lid", "value"))
    xx <- cbind(xx[,-3], splitlocation(xx$value)[,-3])
    names(x)[3] <- "perc.dist"
    x$perc.dist <- as.numeric(as.character(x$perc.dist))
    names(xx)[3:4] <- c("along", "alat")
    x <- merge(x, xx, by=c("sid", "lid"), all=T)
    for (p in c("s", "l")) {
        names(mm) <- paste(p, c("id", "sex", "lang", "lat"), sep="")
        print(names(mm)[1])
        x <- merge(x, mm, by=names(mm)[1])
    }
    if (export) {
        write.csv(file="tables/export/martijn.csv", x)
    }
    x
}

select.stef <- function(a=read.csv("tables/answers.csv"), m=read.meta(), recordings=read.recordings(),
                        export = FALSE) {
    ## geslacht, waar vandaan, geboortejaar
    base <- (!is.na(m$q07) & !is.na(m$q03) & !is.na(m$q05))
    age <- 2016 - m$q05
    base <- base & (20 <= age) & (age <= 40)  & (m$q07 == "Man")
    m <- m[base,]
    ## find municipality and province
    P4S.latlon <- CRS("+proj=longlat +datum=WGS84")
    loc <- SpatialPoints(splitlocation(m$q03), proj4string=P4S.latlon)
    region <- NLD_muni
    locp <- spTransform(loc, region@proj4string)
    locdata <- over(locp, region)
    m$muni <- locdata$name
    m$prov <- locdata$province
    m <- subset(m, prov %in% c("Groningen", "Drenthe", "Gelderland", "Limburg", "Noord-Holland", "Zuid-Holland"))
    m$prov <- factor(m$prov)
    ##
    recordings <- subset(recordings, pid %in% m$pid & text_group_id == 9) ## utype == "speech"
    dur <- aggregate(cbind(nrec, dur) ~ pid, transform(recordings, nrec=1), sum)
    dur <- subset(dur, dur > 15)
    m <- merge(m, dur, by="pid")
    if (export) {
        a <- subset(a, sid %in% m$pid & utype=="speech")
        recordings <- subset(recordings, pid %in% m$pid)
        write.csv(file="tables/export/stef-meta.csv", m)
        write.csv(file="tables/export/stef-answers.csv", a)
        write.csv(file="tables/export/stef-recordings.csv", recordings)
    }
    m
}

twente <- c("Haaksbergen", "Almelo", "Borne", "Dinkelland", "Enschede", "Haaksbergen", "Hellendoorn",
            "Hengelo", "Hof van Twente", "Losser", "Oldenzaal", "Rijssen-Holten",
            "Tubbergen", "Twenterand", "Wierden")
tgooi <- c("Hilversum", "Bussum", "Naarden", "Huizen", "Laren", "Blaricum")
steden <- c("Amsterdam", "Rotterdam", "Den Haag", "Utrecht", "Volendam")

add.muni.province <- function(m=read.meta(), inc.twente=F, inc.tgooi=F, inc.cities=F) {
    P4S.latlon <- CRS("+proj=longlat +datum=WGS84")
    loc.known <- !is.na(m$q03)
    loc <- SpatialPoints(splitlocation(m$q03[loc.known]), proj4string=P4S.latlon)
    region <- NLD_muni
    locp <- spTransform(loc, region@proj4string)
    locdata <- over(locp, region)
    m$muni[loc.known] <- as.character(locdata$name)
    m$prov[loc.known] <- as.character(locdata$province)
    if (inc.twente)
        m$prov[m$muni %in% twente] <- "Twente"
    if (inc.tgooi)
        m$prov[m$muni %in% tgooi] <- "tGooi"
    if (inc.cities)
        m$prov[m$muni %in% steden] <- m$muni[m$muni %in% steden]
    return(m)
}

loc2muni.prov <- function(x, inc.regions=FALSE) {
    P4S.latlon <- CRS("+proj=longlat +datum=WGS84")
    loc.known <- !is.na(x)
    coords <- splitlocation(x)
    loc <- SpatialPoints(coords[loc.known,], proj4string=P4S.latlon)
    region <- NLD_muni
    locp <- spTransform(loc, region@proj4string)
    locdata <- over(locp, region)
    coords$muni[loc.known] <- as.character(locdata$name)
    coords$prov[loc.known] <- as.character(locdata$province)
    if (inc.regions) {
        coords$prov[coords$muni %in% twente] <- "Twente"
        coords$prov[coords$muni %in% tgooi] <- "tGooi"
        coords$prov[coords$muni %in% steden] <- coords$muni[coords$muni %in% steden]
    }
    return(coords)
}

select.eva <- function(a=read.csv("tables/answers.csv"), m=read.meta(), recordings=read.recordings(),
                       export=FALSE) {
    ## geslacht, waar langst gewoond, geboortejaar
    base <- (!is.na(m$q07) & !is.na(m$q03) & !is.na(m$q05))
    age <- 2016 - m$q05
    base <- base & (20 <= age) & (age <= 40) & !is.na(m$q33)
    m <- m[base,]
    ## find municipality and province
    m <- add.muni.province(m, TRUE)
    m <- subset(m, q33 >= "HBO/HEAO/PABO/HTS" | (prov %in% c("Limburg", "Groningen") & q33 == "VWO/Gymnasium"))
    m <- subset(m, prov %in% c("Groningen", "Noord-Holland", "Twente", "Limburg"))
    m$prov <- factor(m$prov)
    ## duration statistics
    dur <- aggregate(cbind(nrec, dur) ~ pid, transform(recordings, nrec=1), sum)
    m <- merge(m, dur, by="pid")
    if (export) {
        a <- subset(a, sid %in% m$pid)
        recordings <- subset(recordings, pid %in% m$pid)
        write.csv(file="tables/export/eva-meta.csv", m)
        write.csv(file="tables/export/eva-answers.csv", a)
        write.csv(file="tables/export/eva-recordings.csv", recordings)
    }
    m
}

eva.locations <- function(a, eva.meta, export=FALSE) {
    eva.speakers <- unique(eva.meta$pid)
    a.eva <- subset(a, sid %in% eva.speakers & qid %in% c("q75", "q76", "q82"))
    a.eva <- cbind(a.eva, loc2muni.prov(a.eva$value, TRUE))
    if (export) {
        write.csv(file="tables/export/eva-answers-locations.csv", a.eva)
    }
    a.eva
}

per.prov <- function(q, title, a, m, type="num") {
    aa <- subset(a, qid %in% c(q))
    if (type=="num")
        aa$value <- as.numeric(as.character(aa$value))
    else {
        aa$value <- as.character(aa$value)
        if (all(aa$value %in% c("Ja", "Nee"))) {
            aa$value <- ordered(aa$value, levels=c("Nee", "Ja"))
        }
    }
    ncol <- length(unique(aa$value))
    mm <- m
    names(mm)[1] <- "sid"
    aa <- merge(aa, mm, by="sid")
    t <- table(aa$prov, aa$value)
    plot(t / apply(t, 1, sum), col=rainbow(ncol, start=0, end=1/3), las=2, main=title, cex=1)
    t
}

aantrekkelijk <- c("q63", "q79", "q87", "q89")

answer.dirk <- function(a=read.csv("tables/answers.csv"), m=read.meta(), questions=read.table("questions.txt", sep="\t", col.names=c("qid", "question")), q, type="num", region=TRUE) {
    base <- !is.na(m$q03) ## langst gewoond
    m <- m[base,]
    m <- add.muni.province(m, region)
    qid = sprintf("q%02d", q)
    per.prov(qid, questions$question[q], a, m, type)
}

answer.dirk2 <- function(a=read.csv("tables/answers.csv"), m=read.meta(), type="num", region=TRUE) {
    base <- !is.na(m$q03) ## langst gewoond
    m <- m[base,]
    m <- add.muni.province(m, region)
    per.prov(aantrekkelijk, "Aantrekkelijk", a, m, type)
}

## rolechar is "l" for listener, "s" for speaker
merge.muni.prov <- function(a, m, rolechar) {
    stopifnot(rolechar %in% c("s", "l"))
    m <- data.frame(pid=m$pid, x.muni=m$muni, x.prov=m$prov)
    for (i in 1:3) substr(names(m)[i], 1, 1) <- rolechar
    merge(a, m, by=names(m)[1])
}

answer.dirk3 <- function(v = value.answers(read.answers("tables/answers.csv")), m=read.meta(), export=FALSE) {
    m <- add.muni.province(m, T, T, T)
    v <- merge.muni.prov(v, m, "s")
    v <- merge.muni.prov(v, m, "l")
    x <- aggregate(cbind(value, count) ~ s.prov + l.prov + qid, transform(v, count=1), sum)
    x$value <- x$value / x$count
    if (export) {
        write.csv(aggregate(value ~ s.prov + qid, x, mean), "tables/export/dirk-speaker-region.csv")
        write.csv(x, "tables/export/dirk-speaker-listener-region.csv")
    }
    x
}

read.recordings <- function() {
    recordings <- read.csv("tables/dump/recordings.csv")
    names(recordings)[2] <- "pid"
    durations <- read.csv("tables/audio/durations.csv")
    recordings <- merge(recordings, durations, by=c("pid", "file"))
    recordings$file <- gsub("\\.m4a|\\.mp4", ".wav", recordings$file)
    recordings
}

## simply add all metadata for all speakers and listeners
select.borja <- function(a=read.csv("tables/answers.csv"), m=read.meta(), export=FALSE) {
    n <- names(m)
    names(m) <- paste("s", n, sep=".")
    names(m)[1] <- "sid"
    a <- merge(a, m, by="sid")
    names(m) <- paste("l", n, sep=".")
    names(m)[1] <- "lid"
    a <- merge(a, m, by="lid")
    if (export) {
        write.csv(file="tables/export/borja-answers.csv", a)
    }
    a
}
