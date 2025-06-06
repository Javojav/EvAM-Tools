## This test was very kludgy as it used as reference
## a set of defaults that one might one to change.
## And that object (.ev_SHINY_dflt) is loaded implicitly.

## So now we create a function that is only used to
## generate that old default, for the pieces that are needed.
## And yes, this is OK. All these tests are transformations, that changing
## something works. So we just use the same standard that is expected.
## What changes,now, is that we are explicit about the standard (whatever
## is produced by generate_old) instead of using, in a non-explicit
## way, whatever is in a different object, which we might want to
## modify anyway.

t1 <- Sys.time()

generate_old <- function() {
    ## default_genes <- 3
    max_genes <- 10
    all_gene_names <- LETTERS[1: max_genes]
    template_dag <- matrix(0, ncol = max_genes + 1, nrow = max_genes + 1)
    rownames(template_dag) <- colnames(template_dag) <- c("Root", all_gene_names)
    template_parent_set <- rep("Single", max_genes)
    names(template_parent_set) <- all_gene_names
    template_lambdas <- rep(1, max_genes)
    names(template_lambdas) <- all_gene_names
    template_thetas <- matrix(0, ncol = max_genes, nrow = max_genes)
    rownames(template_thetas) <- colnames(template_thetas) <- all_gene_names
    template_csd_counts <- data.frame(Genotype = character(), Counts = integer())
    template_csd_data <- matrix(0, ncol=3, nrow=0)


    old_.ev_SHINY_dflt <- list(
        max_genes = 10,
        ## min_genes = 2,
        ## cpm_samples = 10000,
        ## ngenes = 3,
        ## csd_samples = 1000,
        ## dag_model = "HESBCN",
        ## all_cpms = c("OT", "CBN", "OncoBN", "MHN", "MCCBN", "HESBCN"),
        ## cpms2run = c("OT", "CBN", "OncoBN", "MHN"), ## , "HESBCN"),
        template_data = list(
            csd_counts =  template_csd_counts
          , data = NULL
          , dag = template_dag
          , DAG_parent_set = template_parent_set
          , lambdas = template_lambdas
          , thetas = template_thetas
          , gene_names = LETTERS[1: max_genes]
          , name = "New_CSD"
        )
    )
    return(old_.ev_SHINY_dflt)
}




test_that("Test standarize datasets works correctly", {
    old <- generate_old()
    
    check_fields <- function(orig_data, expected_data) {
        standard_data <- to_stnd_csd_dataset(orig_data,
                                             default_max_genes = old$max_genes,
                                             default_template_data = old$template_data
                                             )
        expected_attr <- names(expected_data)
        for(i in expected_attr){
            expect_equal(standard_data[[i]], expected_data[[i]])
        }
        for(i in setdiff(names(standard_data), expected_attr)){
            ## The rest has to be equal to .ev_SHINY_dflt
            if(i == "gene_names" & "data" %in% names(orig_data)) next
            if(i == "csd_counts" & "data" %in% names(orig_data)) next
            ## this I added recently so cannot expect it to be in the old format
            if (i == "this_d_dag_model") next 
            expect_equal(unname(standard_data[[i]])
                       , unname(old$template_data[[i]]))
        }
        ## I am not sure this is really testing anything
        ## that is not true by construction in most cases.
        expect_equal(standard_data$gene_names, colnames(standard_data$thetas))
        expect_equal(c("Root", standard_data$gene_names), colnames(standard_data$dag))
        expect_equal(standard_data$gene_names, names(standard_data$DAG_parent_set))
        expect_equal(standard_data$gene_names, names(standard_data$lambdas))
        if(!is.null(standard_data$data)){
            expect_equal(standard_data$gene_names[1: ncol(standard_data$data)], 
                         colnames(standard_data$data))
        }
    }

    test_data <- examples_csd$csd$AND$data

    data1 <- NULL

                                        # Try with a CSD
    data2 <- list(data = test_data)

    tmp_data3 <- test_data
    colnames(tmp_data3) <- c("A1", "C2", "D3", "X4")
    data3 <- list(data = tmp_data3)
    expected_gene_names_3 <- c("A1", "C2", "D3", "X4",  "E", "F", "G", "H", "I", "J")

    tmp_lambdas <- c(1,2,3,4)
    names(tmp_lambdas) <- c("z", "x", "y", "w")
    data4 <- list(lambdas = tmp_lambdas, data = tmp_data3) ## Different gene names

    expected_lambdas_4 <- rep(1, 10)
    expected_lambdas_4[1:4] <- tmp_lambdas
    names(expected_lambdas_4) <- c("A1", "C2", "D3", "X4", "E", "F", "G", "H", "I", "J")

                                        # Try with a DAG
    test_dag <- matrix(c(
        c(0, 1, 0, 0, 0),
        c(0, 0, 1, 1, 0),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 0)
    ), byrow = TRUE, ncol=5
    )
    colnames(test_dag) <- rownames(test_dag) <- c("Root", "A1", "B2", "C3", "D4")
    
    parent_set_5 <- c("Single", "OR", "AND", "AND")
    names(parent_set_5) <- c("x1", "x2", "x3", "x4")

    lambdas_5 <- c(1, 2, 3)
    data5 <- list(dag = test_dag
                , lambdas = lambdas_5
                , DAG_parent_set = parent_set_5
                  )

    gene_names_5 <- c("A1", "B2", "C3", "D4", "E", "F", "G", "H", "I", "J")
    parent_set_5 <- rep("Single", 10)
    parent_set_5[4] <- "AND"
    names(parent_set_5) <- gene_names_5 

    expected_dag_5 <- matrix(0, nrow=11, ncol = 11)
    colnames(expected_dag_5) <- rownames(expected_dag_5) <- c("Root", gene_names_5)
    expected_dag_5[1:5, 1:5] <- test_dag 
    expected_lambdas_5 <- c(lambdas_5, rep(1, 7))
    names(expected_lambdas_5) <- gene_names_5
    expected_data_5 <- list(
        dag = expected_dag_5,
        DAG_parent_set = parent_set_5,
        gene_names = gene_names_5,
        lambdas = expected_lambdas_5
    )

    ## Try with a Matrix
    test_thetas <- matrix(c(
        c(-1, 1, 1, 3),
        c(1, 3, 2, 1),
        c(0.5, 0, 0, 1),
        c(0.7, 0, 0, 0)
    ), byrow = TRUE, ncol = 4
    )
    colnames(test_thetas) <- rownames(test_thetas) <- c("A1", "B2", "C3", "D4")
    gene_names_6 <- c("A1", "B2", "C3", "D4", "E", "F", "G", "H", "I", "J")

    data6 <- list(thetas = test_thetas)
    expected_thetas_6 <- matrix(0, ncol=10, nrow = 10)
    colnames(expected_thetas_6) <- rownames(expected_thetas_6) <- gene_names_6

    expected_thetas_6[1:4, 1:4] <- test_thetas
    expected_data_6 <- list(thetas = expected_thetas_6, gene_names = gene_names_6)

    data7 <- list()

    data8 <- list(gene_names = LETTERS[3:20])
    expected_data_8 <- list(gene_names = LETTERS[3:12])

    check_fields(data1, list())
    
    check_fields(data2, list(data = test_data))
    check_fields(data3, list(data = tmp_data3
                           , gene_names = expected_gene_names_3))
    check_fields(data4, list(
                            data = tmp_data3,
                            gene_names = expected_gene_names_3, 
                            lambdas = expected_lambdas_4))
    check_fields(data5, expected_data_5)
    check_fields(data6, expected_data_6)
    check_fields(data7, list())
    check_fields(data8, expected_data_8)

    tmp_data <- test_data
    colnames(tmp_data) <- c("A1", "C2", "D3", "X4")

    test_dag <- matrix(c(
        c(0, 1, 0, 0, 0),
        c(0, 0, 1, 1, 0),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 0)
    ), byrow = TRUE, ncol=5
    )
    colnames(test_dag) <- rownames(test_dag) <- c("Root", "A1", "B2", "C3", "D4")

    lambdas <- c(1,2,3,4)
    names(lambdas) <- c("z", "x", "y", "w")

    parent_set <- c("Single", "OR", "AND", "AND")
    names(parent_set) <- c("x1", "x2", "x3", "x4")

    gene_names <- c("Z1", "X2", "Y3", "W4", "E", "F", "G", "H", "I", "J")

    test_thetas <- matrix(c(
        c(-1, 1, 1, 3),
        c(1, 3, 2, 1),
        c(0.5, 0, 0, 1),
        c(0.7, 0, 0, 0)
    ), byrow = TRUE, ncol=4
    )
    colnames(test_thetas) <- rownames(test_thetas) <- c("A1", "B2", "C3", "D4")
    
    data <- list(dag = test_dag
               , data = tmp_data
               , lambdas = lambdas
               , DAG_parent_set = parent_set
               , gene_names = gene_names 
               , thetas = test_thetas
                 )

    expected_data <- tmp_data
    colnames(expected_data) <- gene_names[1 : ncol(expected_data)]

    expected_dag <- matrix(0, nrow=11, ncol = 11)
    colnames(expected_dag) <- rownames(expected_dag) <- c("Root", gene_names)
    expected_dag[1:5, 1:5] <- test_dag 

    expected_thetas <- matrix(0, nrow=10, ncol = 10)
    colnames(expected_thetas) <- rownames(expected_thetas) <- gene_names
    expected_thetas[1:4, 1:4] <- test_thetas 

    expected_lambdas <- c(lambdas, rep(1, 6))
    names(expected_lambdas) <- gene_names

    expected_parent_set <- c("Single", "Single", "Single", "AND", rep("Single", 6))
    names(expected_parent_set) <- gene_names

    expected_data <- list(
        data = expected_data,
        dag = expected_dag,
        DAG_parent_set = expected_parent_set,
        lambdas = expected_lambdas,
        gene_names = gene_names,
        thetas = expected_thetas
    )

    check_fields(data, expected_data)
})

test_that("Standarize does not work with bad data", {
 old <- generate_old()
    expect_error(to_stnd_csd_dataset("asd",
                                    default_template_data = old$template_data,
                                    default_max_genes = old$max_genes
                                    )
               , "Input data should be a list")

    test_data <- examples_csd$csd$AND$data
    test_data[10, 1] <- 42
                                        # Try with a CSD
    data1 <- list(data = test_data)

    expect_error(to_stnd_csd_dataset(data1, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes
                                    )
               , "Data should be binary: only 0 and 1")

                                        # Try with a DAG
    test_dag <- matrix(c(
        c(0, 1, 0, 0, 0),
        c(0, 0, 1, 1, 0),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 1),
        c(0, 0, 0, 0, 0)
    ), byrow = TRUE, ncol=5
    )
    colnames(test_dag) <- rownames(test_dag) <- c("Root", "A1", "B2", "C3", "D4")
    
    dag_1 <- test_dag
    dag_1["D4", "A1"] <- 1 #Breaks DAG
    test_dag_1 <- list(dag = dag_1)
    expect_error(to_stnd_csd_dataset(test_dag_1, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes),
                 "The graph is not a DAG")
    
    dag_2 <- test_dag
    dag_2["A1", "A1"] <- 1 #Breaks DAG
    test_dag_2 <- list(dag = dag_2)
    expect_error(to_stnd_csd_dataset(test_dag_2, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes),
                 "The graph is not a DAG")

    dag_3 <- test_dag
    dag_3["A1", "B2"] <- 2 #Bad input
    test_dag_3 <- list(dag = dag_3)
    expect_error(to_stnd_csd_dataset(test_dag_3, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes)
               , "Adjacency matrix should be binary: only 0 and 1")

    dag_4 <- test_dag
    dag_4["A1", "B2"] <- "abc" #Bad input
    test_dag_4 <- list(dag = dag_4)
    expect_error(to_stnd_csd_dataset(test_dag_4, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes)
               , "Adjacency matrix should be binary: only 0 and 1")
    
    parent_set <- c("Single", "OR", "AND2", "AND") #Bad data relationships
    test_parent_set <- list(DAG_parent_set = parent_set)
    expect_error(to_stnd_csd_dataset(test_parent_set, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes)
               , "Parent set must include only 'Single', 'AND', 'OR' or 'XOR'")

    lambdas <- c(1, "AB", 4)
    test_lambdas <- list(lambdas = lambdas)
    expect_error(to_stnd_csd_dataset(test_lambdas, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes)
               , "Lambdas should only contain numbers")

    ## Try with a Matrix
    thetas <- matrix(c(
        c(-1, "abc", 1, 3),
        c(1, 3, 2, 1),
        c(0.5, 0, 0, 1),
        c(0.7, 0, 0, 0)
    ), byrow = TRUE, ncol=4
    )
    colnames(thetas) <- rownames(thetas) <- c("A1", "B2", "C3", "D4")

    test_thetas <- list(thetas = thetas)
    expect_error(to_stnd_csd_dataset(test_thetas, default_template_data = old$template_data,
                                    default_max_genes = old$max_genes)
               , "Theta matrix should only contain numbers")
})

test_that("Create tabular data from CPM output works correctly", {
  ## Toy dataset is a combination of the output of evam and sample_all_CPMs
  ## We only define those attr that are going to be processed and we work only with 3 CPMs
  
  attr_to_make_tabular <- c("trans_mat", "trans_rate_mat", "obs_genotype_transitions"
      , "predicted_genotype_freqs", "sampled_genotype_counts")
  methods2test <- c("OT", "CBN", "MHN")
  cpm_out <- list()
  
  # pm <- function(mat,varname="out"){
  #   mat <- round(as.matrix(mat), 3)
  #   genots <- colnames(mat)
  #   genots <- toString(sapply(genots, function(x) paste0("'", x, "'")))
  #   command <- paste0(varname, " <- sparseMatrix(c(", toString(which(mat>0, arr.ind=TRUE)[,"row"]), "), c(",
  #     toString(which(mat>0, arr.ind=TRUE)[,"col"]), "), ",
  #     "x=c(", toString(mat[which(mat>0)]), "), dims=c(", toString(dim(mat)), "));colnames(", varname,") <- rownames(", varname, ") <- c("
  #     , genots, ")")
  #   print(command)
  # }

  # cpm_output <- sample_evam_output$cpm_output
  # for(i in c("MHN", "OT", "CBN")){
  #   for(attr in c("trans_mat", "trans_rate_mat", "obs_genotype_transitions")){
  #     varname <- paste0(i, "_", attr)
  #     mat <- cpm_output[[varname]]
  #     print(varname)
  #     if(!is.null(mat)) pm(mat, varname)
  #   }
  # }
  

  MHN_trans_mat <- sparseMatrix(c(1, 1, 1, 2, 3, 2, 4, 3, 4, 5, 6, 7), 
    c(2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8), 
    x=c(0.464, 0.534, 0.001, 0.928, 0.223, 0.072, 0.072, 0.777, 0.928, 1, 1, 1), dims=c(8, 8))
  colnames(MHN_trans_mat) <- rownames(MHN_trans_mat) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$MHN_trans_mat <-MHN_trans_mat

  MHN_trans_rate_mat <- sparseMatrix(c(1, 1, 1, 2, 3, 2, 4, 3, 4, 5, 6, 7), 
    c(2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8), 
    x=c(25.28, 29.079, 0.08, 0.497, 0.164, 0.038, 25.28, 0.571, 327.013, 0.273, 5.585, 0.164), dims=c(8, 8))
  colnames(MHN_trans_rate_mat) <- rownames(MHN_trans_rate_mat) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$MHN_trans_rate_mat <- MHN_trans_rate_mat

  MHN_obs_genotype_transitions <- sparseMatrix(c(1, 1, 1, 2, 3, 2, 4, 3, 4, 5, 6, 7), 
    c(2, 3, 4, 5, 5, 6, 6, 7, 7, 8, 8, 8), 
    x=c(4546, 5235, 19, 1506, 481, 125, 1, 1688, 18, 418, 102, 239), dims=c(8, 8))
  colnames(MHN_obs_genotype_transitions) <- rownames(MHN_obs_genotype_transitions) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$MHN_obs_genotype_transitions <- MHN_obs_genotype_transitions
  MHN_predicted_genotype_freqs <- c(0.018, 0.297, 0.302, 0, 0.155, 0.002, 0.15, 0.076)
  names(MHN_predicted_genotype_freqs) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$MHN_predicted_genotype_freqs <- MHN_predicted_genotype_freqs
  MHN_sampled_genotype_counts <- c(182, 2993, 2928, 1551, 0, 14, 1522, 810)
  names(MHN_sampled_genotype_counts) <- c('WT', 'A', 'B', 'A, B', 'C', 'A, C', 'B, C', 'A, B, C')
  cpm_out$MHN_sampled_genotype_counts <- MHN_sampled_genotype_counts

  CBN_trans_mat <- sparseMatrix(c(1, 1, 2, 3, 3, 4, 5), 
    c(2, 3, 4, 4, 5, 6, 6), 
    x=c(0.002, 0.998, 1, 0.999, 0.001, 1, 1), dims=c(6, 6))
  colnames(CBN_trans_mat) <- rownames(CBN_trans_mat) <- c('WT', 'A', 'B', 'A, B', 'B, C', 'A, B, C')
  cpm_out$CBN_trans_mat <- CBN_trans_mat

  CBN_trans_rate_mat <- sparseMatrix(c(1, 1, 2, 3, 3, 4, 5), 
    c(2, 3, 4, 4, 5, 6, 6), 
    x=c(1.303, 765.333, 765.333, 1.303, 0.002, 0.002, 1.303), dims=c(6, 6))
  colnames(CBN_trans_rate_mat) <- rownames(CBN_trans_rate_mat) <- c('WT', 'A', 'B', 'A, B', 'B, C', 'A, B, C')
  cpm_out$CBN_trans_rate_mat <- CBN_trans_rate_mat
  CBN_obs_genotype_transitions <- sparseMatrix(c(1, 1, 2, 3, 3, 4, 5), 
    c(2, 3, 4, 4, 5, 6, 6), 
    x=c(22, 9964, 22, 5631, 8, 9, 3), dims=c(6, 6))
  colnames(CBN_obs_genotype_transitions) <- rownames(CBN_obs_genotype_transitions) <- c('WT', 'A', 'B', 'A, B', 'B, C', 'A, B, C')
  cpm_out$CBN_obs_genotype_transitions <- CBN_obs_genotype_transitions
  CBN_predicted_genotype_freqs <- c(0.001, 0, 0.432, 0, 0.564, 0, 0, 0.001)
  names(CBN_predicted_genotype_freqs) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$CBN_predicted_genotype_freqs <- CBN_predicted_genotype_freqs

  CBN_sampled_genotype_counts <- c(17, 0, 4354, 5613, 0, 0, 2, 14)
  names(CBN_sampled_genotype_counts) <- c('WT', 'A', 'B', 'A, B', 'C', 'A, C', 'B, C', 'A, B, C')
  cpm_out$CBN_sampled_genotype_counts <- CBN_sampled_genotype_counts

  OT_trans_mat <- sparseMatrix(c(1, 1, 2, 3, 3, 4, 5), 
    c(2, 3, 4, 4, 5, 6, 6), 
    x=c(0.438, 0.562, 1, 0.614, 0.386, 1, 1), dims=c(6, 6))
  colnames(OT_trans_mat) <- rownames(OT_trans_mat) <- c('WT', 'A', 'B', 'A, B', 'B, C', 'A, B, C')
  cpm_out$OT_trans_mat <- OT_trans_mat 
  cpm_out$OT_trans_rate_mat <- NULL
  cpm_out$OT_obs_genotype_transitions <- NULL
  OT_predicted_genotype_freqs <- c(0.149, 0.169, 0.213, 0, 0.241, 0, 0.107, 0.121)
  names(OT_predicted_genotype_freqs) <- c('WT', 'A', 'B', 'C', 'A, B', 'A, C', 'B, C', 'A, B, C')
  cpm_out$OT_predicted_genotype_freqs <- OT_predicted_genotype_freqs
  cpm_out$OT_sampled_genotype_counts <- NULL


  tabular_data <- create_tabular_data(cpm_out)
  expect_equal(1,
               length(unique(
                   colSums(tabular_data$sampled_genotype_counts[, -c(1, 2)]))))

  for(method in methods2test){
    if(method == "OT"){
      expect_equal("OT" %in% colnames(tabular_data$sampled_genotype_counts), FALSE)
      expect_equal("OT" %in% colnames(tabular_data$obs_genotype_freqs), FALSE)
      expect_equal("OT" %in% colnames(tabular_data$trans_rate_mat), FALSE)
    }else{
      for(genotype in tabular_data$sampled_genotype_counts$Genotype){
        expect_equal(tabular_data$sampled_genotype_counts[genotype, method]
          , as.numeric(cpm_out[[paste0(method, 
            "_sampled_genotype_counts")]][genotype]))
      }

      for(genotype in tabular_data$tran_rate_mat$Genotype){
        expect_equal(tabular_data$trans_rate_mat[genotype, method]
          , as.numeric(cpm_out[[paste0(method, "_trans_rate_mat")]][genotype]))
      }

      for(transition in rownames(tabular_data$obs_genotype_transitions)){
        trans <- strsplit(transition, " -> ")[[1]]
        value <- tabular_data$obs_genotype_transitions[transition, method]
        if(value > 0){
          expect_equal(value
            , as.numeric(cpm_out[[paste0(method, 
              "_obs_genotype_transitions")]][trans[[1]], trans[[2]]]))
        }
      }
    }

    for(genotype in tabular_data$trans_mat$Genotype){
        expect_equal(tabular_data$trans_mat[genotype, method]
          , as.numeric(cpm_out[[paste0(method, "_trans_mat")]][genotype]))
      }
    
    for(genotype in tabular_data$predicted_genotype_freqs$Genotype){
        expect_equal(tabular_data$predicted_genotype_freqs[genotype, method]
          , as.numeric(cpm_out[[paste0(method, 
            "_predicted_genotype_freqs")]][genotype]))
      }
  }
})

test_that("reorder_to_standard_order_arbitrary_df", {
    df1 <- data.frame(Genotype = c("A, B", "WT", "A", "A, B, C"),
                      Column_1 = c(19, 2, 3, 4),
                      Column_2 = c(11, 12, 99, 80))

    df1o <- data.frame(Genotype = c("WT", "A", "A, B", "A, B, C"),
                       Column_1 = c(2, 3, 19, 4),
                       Column_2 = c(12, 99, 11, 80))

    expect_true(identical(reorder_to_standard_order_arbitrary_df(df1)[, -1],
                          df1o))


    df2 <- data.frame(A = c(9, 5, 3, 2, 8),
                      B = letters[1:5],
                      Genotype = c("PLK, AM1", "ATP2B2, RB1", "BMN, ORT", "TUV", "SDN, CK9"))

    df2o <- data.frame(Genotype = c("TUV", "AM1, PLK", "ATP2B2, RB1", "BMN, ORT", "CK9, SDN"),
                       A = c(2, 9, 5, 3, 8),
                       B = c("d", "a", "b", "c", "e"))
    expect_true(identical(reorder_to_standard_order_arbitrary_df(df2)[, -1],
                          df2o))


    df3 <- data.frame(A = c(9, 5, 3, 2, 8),
                      B = letters[1:5],
                      Genotype = c("PLK, AM1", "ATP2B2, RB1", "AM1, PLK", "TUV", "SDN, CK9"))

    expect_error(reorder_to_standard_order_arbitrary_df(df3),
                 "x has duplicated genotype names")
})

test_that("reorder_to_standard_order_count_df", {
    ## reorder_to_standard_order_count_df
    ## o loner exists, so use the new incantation
    df1 <- data.frame(Genotype = c("A, B", "WT", "A", "A, B, C"),
                      Counts = c(19, 2, 3, 4))
    df1o <- data.frame(Genotype = c("WT", "A", "A, B", "A, B, C"),
                       Counts = c(2, 3, 19, 4))
    expect_true(identical(reorder_to_standard_order_count_df(df1),
                          df1o))
})


test_that("reorder_genotypes_2_standard_order", {
    g1 <- c("F, B", "B, M", "U, A", "C, F", "H, D, T", "E, A, B", "WT")
    expect_identical(reorder_genotypes_2_standard_order(g1),
                     c("WT", "A, U", "B, F", "B, M", "C, F", "A, B, E", "D, H, T"))

    g5 <- c("TUV", "PLK, AM1", "RB1, ADP2B2", "ORT, BMN", "CK9, SDN",
            "F, B", "B, M", "I, C", "J, H", "H, I")
    expect_identical(reorder_genotypes_2_standard_order(g5),
                     c("TUV", "ADP2B2, RB1", "AM1, PLK", "B, F",
                       "B, M", "BMN, ORT", "C, I", "CK9, SDN",  "H, I", "H, J"))
})


rm(generate_old)
cat("\n Done test.shiny-utils.R. Seconds = ",
    as.vector(difftime(Sys.time(), t1, units = "secs")), "\n")
