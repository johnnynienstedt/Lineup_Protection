## Scrape data for lineup protection analysis

# Johnny Nienstedt 2/4/2024

# Method
{
  # to make this run in less than 3 weeks, we'll do a random sample instead of
  # every single PA. There were 118,000 PAs in 2023, and SH breaks them into
  # 236 500 PA pages. I think we'll be fine taking 4 random PA's from each page.
  # Then with ~1000 PAs, if each takes 20 seconds to scrape, the whole operation
  # will take about 5.5 hours. That's still a lot, but fine to run overnight.
}

# Load libraries
{
  library(RSelenium)
  library(wdman)
  library(netstat)
}

# Prep for data
{
  # set starting page
  p = 1
  
  # set number of pages to scrape
  npages <- 368
  
  df <- data.frame(NA, NA, NA, NA, NA, NA)
  colnames(df) <- c('Date', 'OnDeckBatter', 'OPS+', 'ROB', 'LI', 'Result')
}

# Navigate to Stathead page
{
  #open chrome window
  remote_driver <- rsDriver(browser = "chrome",
                            chromever = "121.0.6167.85",
                            verbose = FALSE,
                            port = free_port())

  url <- "https://stathead.com/users/login.cgi?redirect_uri=https%3A//stathead.com/%23plan_select"

  remDr <- remote_driver$client
  remDr$navigate(url)
  
  # automate login
  cat('Logging in\n')
  username = 'jnasty'
  password = 'Cornsnake36'
  remDr$findElement(using = 'id', 'username')$sendKeysToElement(list(username))
  remDr$findElement(using = 'id', 'password')$sendKeysToElement(list(password))
  remDr$findElement(using = 'id', 'sh-login-button')$clickElement()
  
  Sys.sleep(3)

  # navigate to correct page
  url <- "https://stathead.com/baseball/event_finder.cgi?request=1&suffix=&type=b&event=modPA&year_max=2023&year_min=2023&offset=PAGENUMBER"
  url <- gsub('PAGENUMBER', 500*p, url)
  
  cat("Navigating to first PA page...\n")
  remDr$navigate(url)
  cat("Scraping first PA page\n")
  
  # it takes a while for this page to load. Unfortunately this will repeat
  # every time we load a new page, which will be a huge time suck as just
  # navigating through the 236 pages will take over 2.5 hours.
}

# Commence scraping
{
  for (i in p:npages) {

    # randomly select PAs to sample
    {
      sample <- sample.int(519, 4)
      
      bad = seq(1,519,26)
      
      while (length(setdiff(sample, bad)) < 4) {
        sample <- sample.int(519, 4)
      }
    }
    
    # eliminate last PA of game for each team
    {
      game_pa <- remDr$findElements(using = 'css selector', "[data-stat = 'game_stat_num']")
      
      team_names <- remDr$findElements(using = 'css selector', "[data-stat = 'team_id']")
      
      tm_nms <- c()
      for (i in 1:length(team_names)) {
        tm_nms[i] <- team_names[[i]]$getElementText()[[1]]
      }
      
      for (i in 1:4) {
        while (game_pa[[sample[i] + 1]]$getElementText()[[1]] < game_pa[[sample[i]]]$getElementText()[[1]]) {
          sample[i] <- sample.int(519,4)[1]
          while (sample[i] %in% bad) {
            sample[i] <- sample.int(519,4)[1]
          }
        }
      }
      
      for (i in 1:4) {
        while (!tm_nms[sample[i]] %in% tm_nms[sample[i] + 1:length(tm_nms)]) {
          sample[i] <- sample.int(519,4)[1]
          while (sample[i] %in% bad) {
            sample[i] <- sample.int(519,4)[1]
          }
        }
      }
      
      shown_sample <- (floor(sample*25/26))
    }
    
    # scrape date
    {
      dates <- remDr$findElements(using = 'css selector', "[target = '_blank']")
      
      for (i in 1:4) {
        true_date <- dates[[(shown_sample[i]*3) + 4]]
        df[(p-1)*4 + i,1] <- true_date$getElementText()[[1]]
      }
    }
    
    # scrape name of on-deck batter
    {
      names <- remDr$findElements(using = 'css selector', "[data-stat = 'tm_player']")
      
      outs <- remDr$findElements(using = 'css selector', "[data-stat = 'outs']")
      
      for (i in 1:4) {
        if (outs[[(sample[i]+1)]]$getElementText()[[1]] %in% c("0", "1", "2")) {
          df$OnDeckBatter[(p-1)*4 + i] <- names[[(sample[i]+1)]]$getElementText()[[1]]
        } else {
          df$OnDeckBatter[(p-1)*4 + i] <- names[[(sample[i]+2)]]$getElementText()[[1]]
        }
        
      }
      
      for (i in 1:4) {
        if (outs[[(sample[i]+1)]]$getElementText()[[1]] %in% c("0", "1", "2")) {
          if (strtoi(outs[[(sample[i])]]$getElementText()[[1]]) > strtoi(outs[[(sample[i]+1)]]$getElementText()[[1]])) {
            b <- tm_nms
            b[1:sample[i]] <- 0
            a <- b == team_names[[sample[i]]]$getElementText()[[1]]
            odb_index <- which(a)[1]
            
            df$OnDeckBatter[(p-1)*4 + i] <- names[[odb_index]]$getElementText()[[1]]
          }
        } else {
          if (strtoi(outs[[(sample[i])]]$getElementText()[[1]]) > strtoi(outs[[(sample[i]+2)]]$getElementText()[[1]])) {
            b <- tm_nms
            b[1:sample[i]] <- 0
            a <- b == team_names[[sample[i]]]$getElementText()[[1]]
            odb_index <- which(a)[1]
            
            df$OnDeckBatter[(p-1)*4 + i] <- names[[odb_index]]$getElementText()[[1]]
        }
        }
      }
    }
    
    # scrape OPS+ of on-deck batter
    {
      for (i in 1:4) {
        true_date <- dates[[(shown_sample[i]*3) + 4]]
        true_date$clickElement()
        true_date$clickElement()
        Sys.sleep(3)
        
        myswitch <- function (remDr, windowId) 
        {
          qpath <- sprintf("%s/session/%s/window", remDr$serverURL, 
                           remDr$sessionInfo[["id"]])
          remDr$queryRD(qpath, "POST", qdata = list(handle = windowId))
        }
        
        windows <- remDr$getWindowHandles()
        current_window <- remDr$getCurrentWindowHandle()
        for (k in 1:length(windows)) {
          if (windows[[k]] != current_window) {
            myswitch(remDr, windows[[k]])
            break
          }
        }
        
        br_names <- remDr$findElements(using = 'css selector', "[data-stat = 'player']")
        
        name <- df$OnDeckBatter[(p-1)*4 + i]
        name <- gsub("'", '', iconv(name,to="ASCII//TRANSLIT"))
        len <- nchar(name)
        
        cat("Scraping OPS+ for", name, "\n")
        
        j = 2
        while (TRUE) {
          
          tryCatch(
            {
              match_name <- br_names[[j]]$findChildElement(using = 'tag name', 'a')
            }, 
            error = function(err) {}, 
            message = function(mess) {}
          )
          
          match_name_text <- match_name$getElementText()[[1]]
          mod_name <- substr(match_name_text, 1, nchar(name))
          new_mod_name <- gsub("'", '', iconv(mod_name,to="ASCII//TRANSLIT"))
          if (mod_name == name) {
            break
          }
          j = j + 1
          if (j > 200) {
            break
          }
        }
        
        tryCatch( {
          click_name <- br_names[[j]]$findChildElement(using = 'tag name', 'a')
          fake_name <- br_names[[j+5]]
          
          fake_name$clickElement()
          Sys.sleep(0.5)
          click_name$clickElement()
          Sys.sleep(3)
          }, error = function(err) {},
          message = function(mess) {})
        
        player_ops = tryCatch(
          {
            stats22 <- remDr$findElement(using = 'id', 'batting_standard.2022')
            rawops <- stats22$findChildElement(using = 'css selector', "[data-stat = 'onbase_plus_slugging_plus']")$getElementText()[[1]]
            df$`OPS+`[(p-1)*4 + i] <- strtoi(rawops)
          }, 
          error = function(err) {
            cat('Could not find 2022 OPS+ for', df$OnDeckBatter[(p-1)*4 + i], '\n')
            df$`OPS+`[(p-1)*4 + i] <- NA
          },
          message = function(mess) {}
        )
        
        remDr$closeWindow()
        while (length(remDr$getWindowHandles()) > 1) {
          myswitch(remDr, remDr$getWindowHandles()[[length(remDr$getWindowHandles())]])
          remDr$closeWindow()
        }
        myswitch(remDr, remDr$getWindowHandles()[[1]])
      }
    }
    
    # scrape number of runners on base
    {
      ROBs <- remDr$findElements(using = 'css selector', "[data-stat = 'runners_on_bases']")
      
      for (i in 1:4) {
        df[(p-1)*4 + i,4] <- ROBs[[sample[i]]]$getElementText()[[1]]
      }
    }
    
    # scrape leverage index
    {
      LIs <- remDr$findElements(using = 'css selector', "[data-stat = 'leverage_index']")
      
      for (i in 1:4) {
        df[(p-1)*4 + i,5] <- LIs[[sample[i] + 2]]$getElementText()[[1]]
      }
    }
    
    # scrape outcome of PA
    {
      pa_results <- remDr$findElements(using = 'css selector', "[data-stat = 'event_type']")
      
      for (i in 1:4) {
        df[(p-1)*4 + i,6] <- pa_results[[sample[i]]]$getElementText()[[1]]
      }
      
    }
    
    # move to next page
    {
      if (p == npages) {
        break
      }
      
      cat(paste0("Navigating to next page (", p + 1, ")"),"\n")
      url <- "https://stathead.com/baseball/event_finder.cgi?request=1&suffix=&type=b&event=modPA&year_max=2023&year_min=2023&offset=PAGENUMBER"
      url <- gsub('PAGENUMBER', 500*p, url)
      
      remDr$navigate(url)
      
      p <- p + 1
    }
  }
  
  View(df)
}

# Close server
{
  Sys.sleep(1)
  remDr$close()
  remote_driver$server$stop()
  cat("Server closed.\n")
}