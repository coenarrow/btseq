get_counts <- function(index) {
    # Construct the file paths
    d <- file.path(paste0('Sample_',index), 'Output')

    
    # List the files in the directory and filter using grepl
    file_list <- list.files(d)
    matched_files <- file_list[grepl("(?=.*CpG)(?=.*hist)", file_list, perl = TRUE)]
    
    # Check if any files matched the pattern
    if (length(matched_files) == 0) {
        stop(paste("Error: No CpG histogram file found for Sample_", index))
    }
    
    # Build the path to the histogram file
    h.f <- file.path(d, matched_files[1])
    
    # Check if file exists
    if (!file.exists(h.f)) {
        stop(paste("Error: File", h.f, "does not exist"))
    }
    
    # Read the histogram file, with some error handling
    h <- tryCatch({
        read.table(h.f, sep = '\t', skip = 1, header = TRUE, check.names = FALSE, comment.char = "")
    }, error = function(e) {
        stop(paste("Error reading file", h.f, ":", e$message))
    })
    
    # Read the corresponding sequence file
    seq_file <- paste0('sample', index, '.fa')
    if (!file.exists(seq_file)) {
        stop(paste("Error: Sequence file", seq_file, "does not exist"))
    }
    seq <- readLines(seq_file)[2]
    
    # Count CG occurrences
    n <- length(gregexpr('CG', seq)[[1]])
    
    # Filter h based on condition
    h <- h[h[, 3] + h[, 5] == n, ]
    
    # Initialize a results vector
    s <- integer(n + 1)
    t <- n:0
    for (j in 1:(n + 1)) {
        s[j] <- sum(h[h[, 5] == t[j], 1])
    }
    
    # Return the results vector with an extra count at the beginning
    s <- c(sum(h[, 1]), s)
    return(s)
}

# Print the full filepath to the summary results
cat("Summary results written to:", file.path(getwd(), 'Summary_results.txt'), "\n")

# Read the sample sheet
ss <- read.table('sample_sheet.txt', sep = '\t', header = FALSE, stringsAsFactors = FALSE)
n.s <- nrow(ss)

# Use sapply to apply get_counts function
S <- sapply(1:n.s, get_counts)

# If the result is a matrix, convert to a list of data frames
if (class(S) == "matrix") {
    S <- as.list(data.frame(S))
}

# Create summary results and print to file
N <- unlist(lapply(S, length)) - 2
con <- file('Summary_results.txt', open = 'w')

# Create title for the summary
title <- paste(c('Sample #', 'Gene', 'Sample', 'CpGs', 'All reads', 'All T', paste0('All T - ', 1:max(N))), collapse = '\t')
writeLines(title, con)

# Write the results for each sample
for (i in 1:n.s) {
    line <- paste(c(i, ss[i, 1], ss[i, 2], N[i], S[[i]]), collapse = '\t')
    writeLines(line, con)
}

# Close the file connection
close(con)

