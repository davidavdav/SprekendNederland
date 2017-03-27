## Demo for the DRONGO festival, 1 october 2016
## (c) David A. van Leeuwen

library(tmap)
library(sp)
library(grid) ## in ggplot2

data(NLD_prov, NLD_muni, World)

read.answers <- function(file="tables/answers.csv") {
    x <- read.csv(file, header=T)
    x$utype <- factor(x$utype, levels=c("describe", "words", "sentence", "speech"),
                      ordered=T, labels=c("picture", "words", "sentence", "spontaneous"))
    x
}

read.meta <- function(file="tables/meta-nodistort.csv") {
    m <- read.csv(file)
    q33levels <- read.csv("q33.levels", header=F, stringsAsFactors=F)[[1]]
    m$q33 <- ordered(m$q33, levels=q33levels)
    ## add some meta data
    m$age <- 2016 - m$q05
    m$sex <- m$q07
    m
}

twente <- c("Haaksbergen", "Almelo", "Borne", "Dinkelland", "Enschede", "Haaksbergen", "Hellendoorn",
            "Hengelo", "Hof van Twente", "Losser", "Oldenzaal", "Rijssen-Holten",
            "Tubbergen", "Twenterand", "Wierden")
achterhoek <- c("Aalten", "Berkelland", "Bronckhorst", "Doesburg", "Doetinchem", "Lochem", "Montferland", "Oost Gelre",
            "Oude IJsselstreek", "Winterswijk", "Zutphen")
tgooi <- c("Hilversum", "Bussum", "Naarden", "Huizen", "Laren", "Blaricum")
steden <- c("Amsterdam", "Rotterdam", "'s-Gravenhage", "Utrecht")

splitlocation <- function(x) {
    coords <- data.frame(do.call(rbind, lapply(strsplit(as.character(x), "/"), as.numeric)))
    names(coords) <- c("long", "lat", "zoom")
    coords
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

## rolechar is "l" for listener, "s" for speaker
merge.muni.prov <- function(a, m, rolechar, sex=FALSE) {
    stopifnot(rolechar %in% c("s", "l"))
    m <- data.frame(pid=m$pid, x.muni=m$muni, x.prov=m$prov, x.group=m$group, x.sex=m$q07)
    for (i in 1:5) substr(names(m)[i], 1, 1) <- rolechar
    merge(a, m, by=names(m)[1])
}

loaddata <- function() {
	q <- read.csv("tables/dump/questions.csv")
	row.names(q) <- paste("q", q$id, sep="")
	assign("q", q, envir = .GlobalEnv)
	a <- read.answers("tables/answers.csv")
	m <- read.meta("tables/meta-nodistort.csv")
	m <- add.muni.province(m, inc.twente=T, inc.tgooi=T, inc.cities=T, q="q04")
	a <- merge.muni.prov(a, m, 's', TRUE)
	a <- merge.muni.prov(a, m, 'l', TRUE)
	assign("a", a, envir = .GlobalEnv)
	assign("m", m, envir = .GlobalEnv)
	assign("muni", sort(unique(m$muni)), envir = .GlobalEnv)
	assign("prov", sort(unique(m$prov)), envir = .GlobalEnv)
	value.ids <- subset(q, question_group_id != 8 & component_id == 1)$id
	value.questions <- paste("q", value.ids, sep="")
	yesno.ids <- subset(q, question_group_id != 8 & component_id == 2)$id
	yesno.questions <- paste("q", yesno.ids, sep="")
	v <- subset(a, qid %in% value.questions)
	v$value <- as.numeric(as.character(v$value))
	assign("v", v, envir = .GlobalEnv)
}

## agregate stats we want to show for a particular slider-type question
stats <- function(vv) {
	x <- aggregate(cbind(value, count) ~ l.prov, transform(vv, count=1), sum)
	x$mean <- x$value / x$count - 4
	x
}

showmap <- function(df, muni, title="per provincie") {
	region <- NLD_prov
	region@data <- merge(NLD_prov@data, df, by.x="name", by.y="l.prov", all.x = T)
	g <- tm_shape(region) +
        tm_fill("mean", title=title, style="quantile", n=12, palette="RdYlGn") +
        tm_borders() + tm_layout(frame=F, outer.margins=c(0,0,0,0), bg.color="transparent", legend.title.size = 2)
	here <- NLD_muni
	ind <- here$name == muni
	here@data <- here@data[ind,]
	here@polygons <- here@polygons[ind]
	gg <- tm_shape(here) + tm_fill(col="pink") + tm_borders(col="black", lwd=3)
	return(g + gg)
}

s <- function(mun, question) {
	ma <- grep(paste("^", mun, sep=""), muni, ignore.case=T)
	if (length(ma) < 1) {
		stop("Geen gemeente die start met ", mun)
	} else if (length(ma) > 1) {
		stop("Niet specifiek genoeg: ", muni[ma])
	}
	if (is.numeric(question)) question <- paste("q", question, sep="")
	a <- subset(a, qid == question)
	atype <- unique(a$atype)
	if (length(atype)!=1) stop("Mixed answer type")
	if (atype[1] == "slider") {
		a$value <- as.numeric(as.character(a$value))
	}
	amuni <- subset(a, s.muni == muni[ma])
	if (nrow(amuni) == 0) stop("Geen data voor deze gemeente")
	province <- unique(as.character(amuni$s.prov))
	aprov <- subset(a, s.prov == province)
	city <- muni[ma]
	cat(city, province, as.character(q[question,]$question), "\n")
	if (atype[1] == "slider") {
		dfs <- lapply(list(amuni, aprov, a), stats)
		avscore <- sapply(dfs, function(x) mean(x$mean))
		n <- sapply(dfs, function(x) sum(x$count))
		x <- data.frame(score=avscore, n=n, region=reorder(c(city, paste("Provincie", province, sep="\n"), "Nederland"), 1:3))
		##xx <- barplot(x$score-4, names.arg=row.names(x), main=q[question,]$question)
		##text(x=xx, y = x$score-4, label=paste("n =", x$n), pos=1 + 2*(x$score<4))
		grid.newpage()
		pushViewport(viewport(layout=grid.layout(1, 2)))
		p1 <- ggplot(x, aes(x = region, y = score, fill=score)) + scale_fill_gradient2(low="darkred", mid="yellow", high="darkgreen") +
		   geom_bar(stat="identity", position="dodge") + guides(fill=FALSE) +
		   geom_text(aes(label=paste("n =", n)), vjust = "outward") + scale_colour_brewer("RdYlGn") + labs(x = "mening over regio", y = "score") +
		   theme(text = element_text(size=16)) + ggtitle(q[question,]$question)
		p2 <- showmap(dfs[[1]], city, paste("Positief over", "het accent van", city, sep="\n"))
		print(p1, vp = viewport(layout.pos.row=1, layout.pos.col=1))
		print(p2, vp = viewport(layout.pos.row=1, layout.pos.col=2))
		return(dfs)
	}
}
