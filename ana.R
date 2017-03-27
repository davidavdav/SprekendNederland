## some quick plots...

## metadata with ordered level of education
read.meta <- function() {
    m <- read.csv("tables/meta-nodistort.csv")
    q33levels <- read.csv("q33.levels", header=F, stringsAsFactors=F)[[1]]
    m$q33 <- ordered(m$q33, levels=q33levels)
    ## add some meta data
    m$age <- 2016 - m$q05
    m$sex <- m$q07
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
speaker.recording1 <- function() {
    cmd <- mysql("select profile_id, count(*) as count from recordings group by profile_id")
    x <- read.table(pipe(cmd), header=F, col.names=c("pid", "nrec"))
    breaks <- 0:100
    xx <- subset(x, nrec <= breaks[length(breaks)])
    h <- hist(xx$nrec, breaks=breaks, freq=T)
    plot(h, main="Histogram of number of recordings per speaker", xlab="number of recordings")
    x
}

speaker.recording <- function(recordings=read.recordings()) {
    ta <- table(table(recordings$pid))
    plot(as.numeric(names(ta)), as.numeric(ta), type="h", xlim=c(0,100), lwd=2, xlab="number of recordings", ylab="number of participants making ... recordings", main="Number of recordings per participant")
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

## 3: 2 dec 2015, 50: 18 jan 2016, 154: 1 Mar 2016
speed.log <- function(what="recordings", first=3, last=154) {
    t <- speed(what, makeplot=F)
    t$second <- t$date >= as.Date("2016-01-28") ## Kennis van Nu met Stef en Rosemary
    t$third <- t$date >= as.Date("2016-03-11") ## tijd voor Max
    main <- paste("Rate of receiving", what)
    ylab <- paste(what, "/ minute")
    plot(speed ~ date, t, log="y", type="b", lwd=2, main=main, ylab=ylab) # , ylim=c(0.05, 20))
    m <- lm(log(speed, 10) ~ date + second + third, t, subset=first:last)
    coef <- m$coefficients
    abline(coef[1], coef[2], col="blue")
    abline(coef[1]+coef[3], coef[2], col="blue")
    abline(coef[1]+coef[3]+coef[4], coef[2], col="blue")
    cat("Fitted line:", 100*(1-10^coef[2]), "% drop per day\n")
    m
}

speed.daily <- function(x, what="answers") {
    ndays <- floor(as.numeric(x$date[nrow(x)] - x$date[1]))
    time <- as.numeric(strptime(paste("01-01-1970", x$time), format="%d-%m-%Y %H:%M:%S"))
    d <- density(time, 100, n=2^11)
    d$time <- as.POSIXlt(as.character(d$x), format="%s")
    plot(d$time, d$y * d$n / ndays, main=paste("Average daily rate of receiving", what), type="l", lwd=2, xlab="time", ylab="entries / second")
}

plot.age <- function(m=read.meta()) {
    levels(m$sex) <- c("different", "male", "female")
    ggplot(subset(m, sex != "different"), aes(x=age, group=sex, fill=sex)) + geom_histogram(position="dodge", binwidth=5) + xlim(0, 100) + ggtitle("Distribution of participant's age and sex") + theme(text=element_text(size=20))
}

plot.age1 <- function() {
    x <- read.table(pipe(mysql("select answers.profile_id, answers.answer_numeric from tasks join answers where tasks.answer_id=answers.id and tasks.question_id=5")), header=F, col.names=c("pid", "year"))
    x$age <- 2016 - x$year
    hist(x$age, breaks=seq(0, 120, by=5), col=grey(0.8), xlim=c(0,100), main="Histogram of age", xlab="participant's age")
    x
}

plot.complete.meta <- function(m=read.meta()) {
    ta <- table(apply(!is.na(m), 1, sum)-1)
    plot(as.integer(names(ta)), as.numeric(ta), xlab="number of metadata questions answered", ylab="Number of participants having ... metadata questions answered", main="Metatdata completeness", type="h", lwd=2)
}

library(ggplot2)
library(ggmap)
if (!"map_nl" %in% ls())
    map_nl <- get_map(location="Netherlands", zoom=7)
map <-function(m=read.csv("tables/meta-nodistort"), q="q04") {
    loc <- splitlocation(m[[q]])
    m <- add.muni.province(m, q="q04")
    loc <- cbind(loc, col=factor(m$prov))
    ##    map <- get_map(location = c(left=3, right=7.5, bottom=50.5, top=54), source="osm")
    palette(heat.colors(21))
    ggmap(map_nl) +
        geom_point(data=loc, aes(x=long, y=lat, colour=col), size=2, alpha=1) +
        geom_point(data=loc, aes(x=long, y=lat), col="black", size=0.5, alpha=0.5) +
##        geom_density2d(data=loc, aes(x=long, y=lat), size=0.5, col="red") +
##        stat_density2d(data=loc, aes(x=long, y=lat, fill=..level.., alpha=..level..), size=0.1, geom="polygon") +
##        scale_fill_gradient(low = "green", high = "red") +
        theme(legend.position="none") +
        coord_cartesian(xlim=c(3.1,7.4), ylim=c(50.6, 53.5))
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

questions <- read.csv("tables/dump/questions.csv")
value.ids <- subset(questions, question_group_id != 8 & component_id == 1)$id
value.questions <- paste("q", value.ids, sep="")
yesno.ids <- subset(questions, question_group_id != 8 & component_id == 2)$id
yesno.questions <- paste("q", yesno.ids, sep="")
read.answers <- function(file="tables/answers.csv") {
    x <- read.csv(file, header=T)
    x$utype <- factor(x$utype, levels=c("describe", "words", "sentence", "speech"),
                      ordered=T, labels=c("picture", "words", "sentence", "spontaneous"))
    x
}

value.answers <- function(x) {
    x <- droplevels(subset(x, qid %in% value.questions))
    x$value <- as.numeric(as.character(x$value))
    x
}
yesno.answers <- function(x) {
    x <- droplevels(subset(x, qid %in% yesno.questions))
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
    split <- function(x) {
        if (is.na(x)) c(NA, NA, NA)
        else strsplit(as.character(x), "/")
    }
    coords <- data.frame(do.call(rbind, lapply(split(x), as.numeric)))
    names(coords) <- c("long", "lat", "zoom")
    coords
}

## analysis using tmap
library(tmap)
library(sp)
data(NLD_prov, NLD_muni, World)
## style="quantile", n=10, convert2density=T
plot.tmap <- function(region=NLD_prov, q=read.csv("tables/meta.csv")$q04, title="Sprekend Nederland participation", ...) {
    P4s.Latlon <- CRS("+proj=longlat +datum=WGS84")
    loc <- SpatialPoints(splitlocation(q[!is.na(q)]), proj4string=P4S.latlon)
    locp <- spTransform(loc, region@proj4string)
    a <- aggregate(count ~ name, transform(over(locp, region), count=1), sum)
    a <- merge(region@data, a, by="name", all.x=T)
    region@data <- a[order(a$code),]
    g <- tm_shape(region) +
        tm_fill("count", title=title, ...) +
        tm_borders() + tm_layout(frame=F, outer.margins=c(0,0,0,0), bg.color="transparent", legend.title.size = 2)
    print(g)
    region
}

## replot the above, but with relative participation
plot.tmap.relative <- function(region, ...) {
    region@data <- transform(region@data, rel=1000 * count / population)
    g <- tm_shape(region) +
        tm_fill("rel", title="Participation / population\nin promille", ...) +
        tm_borders() + tm_layout(frame=F, outer.margins=c(0,0,0,0), bg.color="transparent", legend.title.size = 2)
    print(g)
}

## compes all distances from lat/lon/zoom matrix from splitlocation()
distances <- function(m=read.meta(), q="q03") {
    m <- m[!is.na(m[[q]]),]
    llz <- splitlocation(m[[q]])
    P4s.Latlon <- CRS("+proj=longlat +datum=WGS84")
    loc <- SpatialPoints(llz, proj4string=P4S.latlon)
    locp <- spTransform(loc, World@proj4string)
    inNL <- transform(over(locp, World))$name == "Netherlands"
    inNL[is.na(inNL)] <- FALSE
    llz <- llz[inNL,]
    ma <- as.matrix(llz[,1:2])
    m <- m[inNL,]
    d <- spDists(ma, longlat=TRUE)
    dimnames(d) <- list(row.names(m), row.names(m))
    return(d)
}

adddist <- function(a, m=read.meta(), d=distances(m, "q03")) {
    validids <- rownames(d)
    validanswers <- a$lid %in% validids & a$sid %in% validids
    index <- cbind(as.character(a[["lid"]]), as.character(a[["sid"]]))
    a$dist <- NA
    a$dist[validanswers] <- d[index[validanswers,]]
    return(a)
}

## ad: adddist()
plot.dist.hist <- function(ad, classes=FALSE) {
    if (classes)
    hist(ad$dist, col="gray", main="Distances between speaker and listener", xlab="distance (km)", breaks=c(0,10,20,40,80,310))
    else
    hist(ad$dist, col="gray", main="Distances between speaker and listener", xlab="distance (km)")
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

select.stef <- function(a=read.answers(), m=read.meta(), recordings=read.recordings(),
                        export = FALSE) {
    ## find municipality and province
    loc <- loc2muni.prov(m$q03)
    m$muni <- loc$muni
    m$prov <- loc$prov
    ## geslacht, langst gewoond, geboortejaar
    base <- (!is.na(m$q07) & !is.na(m$q03) & !is.na(m$q05))
    age <- 2016 - m$q05
    base <- base & (20 <= age) & (age <= 40)
    mm <- m[base,]
    mm <- subset(mm, prov %in% c("Groningen", "Drenthe", "Gelderland", "Limburg", "Noord-Holland", "Zuid-Holland", "Utrecht", "Overijssel"))
    mm$prov <- factor(mm$prov)
    ##
    recordings <- subset(recordings, pid %in% mm$pid & text_group_id %in% c(1)) ## utype == SP1: Frans' sentences
    dur <- aggregate(cbind(nrec, dur) ~ pid, transform(recordings, nrec=1), sum)
    dur <- subset(dur, dur > 15)
    mm <- merge(mm, dur, by="pid")
    if (export) {
        a <- subset(a, sid %in% mm$pid & qlist == "SP1")
        recordings <- subset(recordings, pid %in% mm$pid)
        write.csv(file="tables/export/stef-meta.csv", m) ## all metadata
        write.csv(file="tables/export/stef-answers.csv", a)
        write.csv(file="tables/export/stef-recordings.csv", recordings)
    }
    mm
}

twente <- c("Haaksbergen", "Almelo", "Borne", "Dinkelland", "Enschede", "Haaksbergen", "Hellendoorn",
            "Hengelo", "Hof van Twente", "Losser", "Oldenzaal", "Rijssen-Holten",
            "Tubbergen", "Twenterand", "Wierden")
achterhoek <- c("Aalten", "Berkelland", "Bronckhorst", "Doesburg", "Doetinchem", "Lochem", "Montferland", "Oost Gelre",
            "Oude IJsselstreek", "Winterswijk", "Zutphen")
tgooi <- c("Hilversum", "Bussum", "Naarden", "Huizen", "Laren", "Blaricum")
steden <- c("Amsterdam", "Rotterdam", "'s-Gravenhage", "Utrecht")

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
        coords$group <- coords$prov
        coords$group[coords$muni %in% twente] <- "Twente"
        coords$group[coords$muni %in% achterhoek] <- "Achterhoek"
        coords$group[coords$muni %in% tgooi] <- "tGooi"
        coords$group[coords$muni %in% steden] <- coords$muni[coords$muni %in% steden]
    }
    return(coords)
}

add.muni.province <- function(m=read.meta(), inc.twente=F, inc.tgooi=F, inc.cities=F, inc.ethnicity=F, q="q03") {
    P4S.latlon <- CRS("+proj=longlat +datum=WGS84")
    loc.known <- !is.na(m[[q]])
    loc <- SpatialPoints(splitlocation(m[[q]][loc.known]), proj4string=P4S.latlon)
    region <- NLD_muni
    locp <- spTransform(loc, region@proj4string)
    locdata <- over(locp, region)
    m$muni[loc.known] <- as.character(locdata$name)
    m$prov[loc.known] <- as.character(locdata$province)
    m$group <- m$prov
    if (inc.twente) {
        m$group[m$muni %in% twente] <- "Twente"
        m$group[m$muni %in% achterhoek] <- "Achterhoek"
    }
    if (inc.tgooi)
        m$group[m$muni %in% tgooi] <- "tGooi"
    if (inc.cities)
        m$group[m$muni %in% steden] <- m$muni[m$muni %in% steden]
    if (inc.ethnicity) {
        meth <- add.ethnicity(m)
        m$group[!is.na(meth$eth)] <- meth$eth[!is.na(meth$eth)]
    }
    return(m)
}

ethnicities <- c("Antilianen/Arubanen", "Marokkanen", "Surinamers", "Turken")
ethnicity.languages <- c("Papiamento", "Berbers/Tamazight", "Sranan Tongo/Surinaams", "Turks", "Arabisch")

add.ethnicity <- function(m=read.meta()) {
    m$eth <- NA
    m$eth[m$q23 %in% ethnicities] = as.character(m$q23[m$q23 %in% ethnicities])
    for (i in 1:5) {
        j = ifelse(i>4, 2, i)
        m$eth[m$q08 == ethnicity.languages[i]] = as.character(ethnicities[j])
    }
    m
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
merge.muni.prov <- function(a, m, rolechar, sex=FALSE) {
    stopifnot(rolechar %in% c("s", "l"))
    m <- data.frame(pid=m$pid, x.muni=m$muni, x.prov=m$prov, x.group=m$group, x.sex=m$q07)
    for (i in 1:5) substr(names(m)[i], 1, 1) <- rolechar
    merge(a, m, by=names(m)[1])
}

answer.dirk3 <- function(v = value.answers(read.answers("tables/answers.csv")), m=read.meta(), export=FALSE) {
    m <- add.muni.province(m, T, T, T, T)
    v <- merge.muni.prov(v, m, "s", T)
    v <- merge.muni.prov(v, m, "l", T)
    x <- aggregate(cbind(value, count) ~ s.group + l.group + s.sex + l.sex + qid, transform(v, count=1), sum)
    x$value <- x$value / x$count
    if (export) {
        write.csv(aggregate(value ~ s.group + s.sex + l.sex + qid, x, mean), "tables/export/dirk-speaker-group-gender.csv")
        write.csv(x, "tables/export/dirk-speaker-listener-group-gender.csv")
    }
    x
}

answer.dirk4 <- function(v = yesno.answers(read.answers("tables/answers.csv")), m=read.meta(), export=FALSE){
    m <- add.muni.province(m, T, T, T, T)
    v <- merge.muni.prov(v, m, "s")
    v <- merge.muni.prov(v, m, "l")
    x <- aggregate(cbind(ja, count) ~ s.group + l.group + qid, transform(v, ja=value=="Ja", count=1), sum)
    x$ja <- x$ja / x$count
    if (export) {
        write.csv(aggregate(ja ~ s.group + qid, x, mean), "tables/export/dirk-yn-speaker-group.csv")
        write.csv(x, "tables/export/dirk-yn-speaker-listener-group.csv")
    }
    x
}

answer.stef1 <- function(v = value.answers(read.answers()), m=read.meta(), export=FALSE) {
    m <- add.muni.province(m, F, F, T, T)
    accent <- aggregate(value ~ sid, subset(v, qid == "q68"), mean)
    names(accent)[2] <- "accent"
    accent$strong <- accent$accent > 4
    v <- subset(v, qid %in% c("q53", "q56", "q57", "q59", "q67") & utype=="spontaneous")
    v <- merge(v, accent, by="sid")
    v <- merge.muni.prov(v, m, "s")
    v <- merge.muni.prov(v, m, "l")
    x <- aggregate(cbind(value, count) ~ s.group + l.group + qid + strong, transform(v, count=1), sum)
    x$value <- x$value / x$count
    if (export) {
        write.csv(aggregate(value ~ s.group + qid + strong, x, mean), "tables/export/stef-speaker-group.csv")
        write.csv(x, "tables/export/stef-speaker-listener-group.csv")
    }
    x
}

## this is not what stef meant
answer.stef2 <- function(v = value.answers(read.answers("tables/answers.csv")), m=read.meta(), export=FALSE) {
    m <- add.muni.province(m, F, F, T, T)
    v <- subset(v, qid == "q68" & value != 4) ## accent strerkte
    v$strongaccent <- v$value > 4
    v <- merge.muni.prov(v, m, "s")
    v <- merge.muni.prov(v, m, "l")
    x <- aggregate(cbind(strongaccent, count) ~ s.group + l.group, transform(v, count=1), sum)
    x$strongaccent <- x$strongaccent / x$count
    if (export) {
        write.csv(aggregate(strongaccent ~ s.group, x, mean), "tables/export/stef-accent-group.csv")
        write.csv(x, "tables/export/stef-accent-listener-group.csv")
    }
    x
}

answer.stef3 <- function(export=FALSE) {
    astef <- subset(read.csv("tables/export/stef-answers.csv", row.names=1), qid %in% c("q75", "q76"))
    astef <- cbind(astef, loc2muni.prov(as.character(astef$value)))
    if (export) {
        write.csv(astef, "tables/export/stef-answers-loc.csv")
    }
    astef
}

meta.eva1 <- function(listeners, m=read.meta(), export=FALSE) {
    m <- subset(m, pid %in% listeners)
    m3 <- loc2muni.prov(m$q03, T)[,-(1:3)]
    names(m3) <- paste("q03", names(m3), sep=".")
    m4 <- loc2muni.prov(m$q04, T)[,-(1:3)]
    names(m4) <- paste("q04", names(m4), sep=".")
    m <- cbind(m, m3, m4)
    if (export) {
        write.csv(m, "tables/export/eva-meta-listeners.csv")
    }
    m
}

## answers by specific listeners for Eva
answers.eva2 <- function(a, export=FALSE) {
    listeners <- unique(read.csv("tables/import/metadata_listeners_subset.csv", sep=';')$pid)
    qids <- paste("q", c(53:74, 79, 83:90), sep="")
    a <- subset(a, qid %in% qids & lid %in% listeners)
    if (export) {
        write.csv(a, "tables/export/eva-answers-2.csv")
    }
    a
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
select.borja <- function(a=read.answers(), m=read.meta(), export=FALSE) {
    m <- add.muni.province(m, T, T, T, T)
    n <- names(m)
    names(m) <- paste("s", n, sep=".")
    names(m)[1] <- "sid"
    a <- merge(a, m, by="sid")
    names(m) <- paste("l", n, sep=".")
    names(m)[1] <- "lid"
    a <- merge(a, m, by="lid")
    if (export) {
        write.csv(a, file=gzfile("tables/export/borja-answers.csv.gz"))
    }
    a
}

## can we correlated answers from the same listeners about the same speakers?

renumber <- function(a) {
    a$value <- as.numeric(as.character(a$value))
    return(a)
}

correlate <- function(a, questions) {
    a1 <- renumber(subset(a, qid==q1))
    a2 <- renumber(subset(a, qid==q2))
    bynames <- names(a)[! names(a) %in% c("qid", "value")]
    merge(a1, a2, by=c("lid", "sid", "prompt", "atype", "qlist", "utype"))
}

prompts <- function(a, ql) {
    a <- subset(a, qlist==ql)
    a$prompt <- factor(a$prompt)
    a$prompt
}

## find prompts with all recordings
read.recordings2 <- function () {
    read.table(pipe(mysql("select texts.text, texts.text_group_id, recordings.id from recordings join tasks, task_text, texts  where recordings.id = tasks.recording_id and task_text.task_id = tasks.id and texts.id = task_text.text_id")), sep="\t", col.names = c("text", "tgid", "rid"))
}

select.aki <- function(a, m, export=FALSE) {
    m <- subset(m, q08 %in% c("Nederlands", "Fries") & !is.na(q01) & !is.na(q02) & !is.na(q03) & !is.na(q04) & !is.na(q21) & ! is.na(q31) & !is.na(q32))
    for (q in c("q03", "q04", "q21", "q31", "q32")) {
        loc <- splitlocation(m[[q]])
        names(loc) <- paste(q, names(loc), sep=".")
        m <- cbind(m, loc)
    }
    if (export) {
        write.csv(m, "tables/export/aki-meta.csv")
    }
    m
}

## similar, but for martijn: all data
select.martijn <- function(m, r=read.recordings(), export=FALSE) {
    m <- subset(m, !is.na(q01) & !is.na(q02) & !is.na(q03) & !is.na(q04) & !is.na(q21) & ! is.na(q31) & !is.na(q32))
    for (q in c("q03", "q04", "q21", "q31", "q32")) {
        loc <- splitlocation(m[[q]])
        names(loc) <- paste(q, names(loc), sep=".")
        m <- cbind(m, loc)
    }
    r <- subset(r, r$pid %in% m$pid)
    if (export) {
        write.csv(m, "tables/export/martijn-meta.csv")
        text = read.csv("tables/recordings.csv")
    }
    m
}


## add recording text to aki's recording data, for martijn
add.martijn <- function(aki=read.csv("tables/export/aki-recordings.csv"), text=read.csv("tables/recordings.csv"), export=FALSE) {
    text = text[,c("rid", "text")]
    aki = aki[,-1] ## remove "X"
    names(aki)[3] <- "rid"
    x <- merge(aki, text, by="rid")
    if (export) {
        write.csv(x, "tables/export/martijn-recordings.csv", row.names=F)
    }
}

large.groups <- function(m) {
    m$group[m$prov %in% c("Groningen", "Friesland", "Drenthe")] <- "Noord"
    m$group[m$prov %in% c("Overijssel", "Gelderland")] <- "Oost"
    m$group[m$prov %in% c("Noord-Brabant", "Limbirg")] <- "Zuid"
    m$group[m$prov %in% c("Noord-Holland", "Zuid-Holland", "Utrecht")] <- "Randstad"
    m <- subset(m, group %in% c("Noord", "Oost", "Zuid", "Randstad"))
    return(m)
}

## as answer.dirk3
answer.lieke <- function(v = value.answers(read.answers("tables/answers.csv")), m=read.meta(), export=FALSE) {
    m <- large.groups(add.muni.province(m, F, F, F, F))
    v <- merge.muni.prov(v, m, "s", F)
    v <- merge.muni.prov(v, m, "l", F)
    x <- aggregate(cbind(value, count) ~ s.group + l.group + qid, transform(v, count=1), sum)
    x$value <- x$value / x$count
    if (export) {
        write.csv(aggregate(value ~ s.group + qid, x, mean), "tables/export/lieke-speaker-group.csv")
        write.csv(x, "tables/export/lieke-speaker-listener-group.csv")
    }
    x
}
