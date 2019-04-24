Data accompanying Poltoratski, Maier, Newton, and Tong. (2019) Figure-ground modulation in the human lateral geniculate nucleus is distinguishable from top-down attention. Current Biology.

Folder structure is organized as: exptName/bilatROI/subj#_voxGLM.mat

Each subj#_voxGLM.mat contains two structures: 
- analysis: specifies details of the analysis method
- cond: 1xnumConds structure with voxelwise GLMs for each region; in cortical ROIs, 100 voxels per hemisphere are used.

Fields in each structure:

analysis = 
		 area: 'bilatLGN'	% ROI name
         trimOutliers: 1		% binary - Windsorizing outliers
        outlierCutoff: 3		% in SDs from the mean
       trimOutsideVol: 1		% binary - NaN out voxels that leave the volume during the run
              dispPre: 3		% for display purposes, TRs before stim onset
             dispPost: 5		% for display purposes, TRs after stim offset
          TRsPerBlock: 8		% for display purposes, TRs in each block; 3+5+8 = length of timeCourse vector
               numTRs: 136		% TRs per run
    percentOutsideVol: 0		% percentage of voxels that were removed because they left the volume
          numOutliers: 5		% total number of outlier points (time x vox) Windsorized
       percentOutlier: 0.2626		% percentage of points (time x vox) Windsorized

cond(1) = 

                 mean: 0.0375		% mean GLM beta
              stError: 0.0388		% stError GLM beta
                betas: [33x1 double]	% all GLM betas (numVox x 1)
       meanTimeCourse: [1x16 double]	% mean timeCourse (see analysis.dispPre, etc)
    stErrorTimeCourse: [1x16 double]	% standardError timeCourse
                 name: 'monoptic-congruent'	% descriptive condition name