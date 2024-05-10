## Protection in the Lineup or just runners on base?

# Johnny Nienstedt 2/9/2024

# Read and clean data
{
  df <- read.csv('/Users/johnnynienstedt/lineupProtData.csv')
  df <- df[,-1]
  
  df <- df[-which(df$OPS. > 210), ]
}

# Get OBP, OPS, ROB for each PA
{
  df$PA <- rep(1, nrow(df))
  df$AB <- rep(NA, nrow(df))
  df$OB <- rep(NA, nrow(df))
  df$TB <- rep(NA, nrow(df))
  df$nrob <- rep(NA, nrow(df))
  
  for (i in 1:nrow(df)) {
    r <- df$Result[i]
    if (r %in% c('Out', 'SO', 'FC', 'RoE')) {
      df$AB[i] <- 1
      df$OB[i] <- 0
      df$TB[i] <- 0
    }
    if (r == 'Catint') {
      df$AB[i] <- 0
      df$OB[i] <- 0
      df$TB[i] <- 0
      df$PA[i] <- 0
    }
    if (r %in% c('BB', 'HBP', 'IBB')) {
      df$AB[i] <- 0
      df$OB[i] <- 1
      df$TB[i] <- 0
    }
    if (r == '1B') {
      df$AB[i] <- 1
      df$OB[i] <- 1
      df$TB[i] <- 1
    }
    if (r == '2B') {
      df$AB[i] <- 1
      df$OB[i] <- 1
      df$TB[i] <- 2
    }
    if (r == '3B') {
      df$AB[i] <- 1
      df$OB[i] <- 1
      df$TB[i] <- 3
    }  
    if (r == 'HR') {
      df$AB[i] <- 1
      df$OB[i] <- 1
      df$TB[i] <- 4
    }
  }
  
  for (i in 1:nrow(df)) {
    n <- df$ROB[i]
    if (n == '---') {
      df$nrob[i] <- 0
    }
    if (n %in% c('1--', '-2-', '--3')) {
      df$nrob[i] <- 1
    }
    if (n %in% c('12-', '-23', '1-3')) {
      df$nrob[i] <- 2
    }
    if (n == '123') {
      df$nrob[i] <- 3
    }
  }
  
  df$OPS <- df$OB/df$PA + df$TB/df$AB
}

# Create groups
{
  df <- df[order(df$OPS., decreasing = TRUE),]
  b1 <- df[which(df$OPS. > 119),]
  b2 <- df[which(df$OPS. > 104 & df$OPS. < 120),]
  b3 <- df[which(df$OPS. > 89 & df$OPS. < 105),]
  b4 <- df[which(df$OPS. < 90),]
  
  r1 <- df[which(df$nrob == 3),]
  r2 <- df[which(df$nrob == 2),]
  r3 <- df[which(df$nrob == 1),]
  r4 <- df[which(df$nrob == 0),]
  
  l1 <- df[which(df$LI >= 1.27),]
  l2 <- df[which(df$LI >= 0.8 & df$LI < 1.27),]
  l3 <- df[which(df$LI >= 0.4 & df$LI < 0.8),]
  l4 <- df[which(df$LI < 0.4),]
}

# Get results
{
  results <- data.frame(rep(NA, 4), rep(NA, 4), rep(NA, 4), rep(NA, 4), rep(NA, 4), rep(NA, 4), row.names = c('Highest', 'Second Highest', 'Second Lowest', 'Lowest'))
  colnames(results) <- c('OPS_by_Protection', 'count', 'OPS_by_ROB', 'count', 'OPS_by_LI', 'count')

  results$OPS_by_Protection[1] <- mean(b1$OPS, na.rm = TRUE)
  results$OPS_by_Protection[2] <- mean(b2$OPS, na.rm = TRUE)
  results$OPS_by_Protection[3] <- mean(b3$OPS, na.rm = TRUE)
  results$OPS_by_Protection[4] <- mean(b4$OPS, na.rm = TRUE)
  results[1,2] <- nrow(b1)
  results[2,2] <- nrow(b2)
  results[3,2] <- nrow(b3)
  results[4,2] <- nrow(b4)
  
  results$OPS_by_ROB[1] <- mean(r1$OPS, na.rm = TRUE)
  results$OPS_by_ROB[2] <- mean(r2$OPS, na.rm = TRUE)
  results$OPS_by_ROB[3] <- mean(r3$OPS, na.rm = TRUE)
  results$OPS_by_ROB[4] <- mean(r4$OPS, na.rm = TRUE)
  results[1,4] <- nrow(r1)
  results[2,4] <- nrow(r2)
  results[3,4] <- nrow(r3)
  results[4,4] <- nrow(r4)
  
  results$OPS_by_LI[1] <- mean(l1$OPS, na.rm = TRUE)
  results$OPS_by_LI[2] <- mean(l2$OPS, na.rm = TRUE)
  results$OPS_by_LI[3] <- mean(l3$OPS, na.rm = TRUE)
  results$OPS_by_LI[4] <- mean(l4$OPS, na.rm = TRUE)
  results[1,6] <- nrow(l1)
  results[2,6] <- nrow(l2)
  results[3,6] <- nrow(l3)
  results[4,6] <- nrow(l4)
  
  View(results)
}

# Plot results
{
  plot(c(4,3,2,1), results$OPS_by_Protection, xlim = c(1,4), ylim = c(0.6,1), col = 'red', pch = 16, type = 'b', main = 'OPS by Group Quartiles', xlab = 'Quartile of Each Metric', ylab = 'Group OPS', xaxt = 'n', yaxt = 'n')
  points(c(4,3,2,1), results$OPS_by_ROB, col = 'blue', type = 'b', pch = 16)
  points(c(4,3,2,1), results$OPS_by_LI, col = 'green', type = 'b', pch = 16)
  axis(1, at = c(1,2,3,4), labels = c('First', 'Second', 'Third', 'Fourth'))
  axis(2, at = c(.6, .7, .8, .9, 1), labels = c('.600', '.700', '.800', '.900', '1.000'))
  legend(1.1,0.95, legend=c("By OPS+ of On-Deck Batter", "By # of Runnners on Base", "By Leverage Index"), col=c("red", "blue", 'green'), lty = c(1,1,1), cex=0.8)
}