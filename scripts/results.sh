#!/bin/bash

# Make group_results folder
mkdir group_results

# Quick Quality check 
gen_ss_review_table.py \
-tablefile group_results/test_qa.tsv \
-infiles *-retest.results/out.ss_review*

# Creating the group mask
3dmask_tool \
-input *-retest.results/mask_group+tlrc.HEAD \
-frac 1.0 \
-prefix group_results/mask

# One-sample t-test of Foot-Lips (I named it as lowercase when I originally ran my data)
3dttest++ -mask group_results/mask+tlrc \
-prefix group_results/Foot-Lips \
-setA '*-retest.results/stats.*-retest+tlrc.HEAD[foot-lips_GLT#0_Coef]'

# Using Averaging Script to get Smoothness Estimation
scripts/average_blur.py *-retest.results/blur.errts.1D

# Clustering
3dClustSim \
-mask group_results/mask+tlrc \
-acf `scripts/average_blur.py *-retest.results/blur.errts.1D` \
-both -pthr .001 \
-athr .05 \
-iter 2000 \
-prefix group_results/cluster \
-cmd group_results/refit.cmd

# Add cluster table
# `cat group_results/refit.cmd` \
# group_results/Foot-Lips+tlrc

# Copy of anat
cp /usr/local/afni/MNI152_T1_2009c+tlrc* group_results/

# Mask the stat image
cd group_results

3dcalc -a Foot-Lips+tlrc \
-b mask+tlrc \
-expr 'a*b' \
-prefix Foot-Lips_masked

# Convert go Z-scores
3dmerge -1zscore -prefix Foot-Lips_zstat \
'Foot-Lips_masked+tlrc[SetA_Tstat]'

# Find clusters 
3dAttribute AFNI_CLUSTSIM_NN3_1sided \
Foot-Lips+tlrc

# Result gives 16.7, or 17 as minimum cluster size

# Find clusters part 2
3dclust -1Dformat -nosum \
-prefix Foot-Lips_clusters \
-savemask Foot-Lips_cluster_mask \
-inmask -1noneg \
-1clip 3 \
-dxyz=1 \
1.74 17 \
Foot-Lips_zstat+tlrc

# Put results in file results/Foot-Lips.txt
touch Foot-Lips.txt
3dclust -1Dformat -nosum \
-prefix Foot-Lips_clusters \
-savemask Foot-Lips_cluster_mask \
-inmask -1noneg \
-1clip 3 \
-dxyz=1 \
1.74 17 \
Foot-Lips_zstat+tlrc > Foot-Lips.txt