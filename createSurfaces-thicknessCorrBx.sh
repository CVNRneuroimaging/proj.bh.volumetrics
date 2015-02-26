#!/bin/sh

# LOCATION:     ~/src.mywork.gitRepos/proj.bh.volumetrics/createSurfaces-thicknessCorrBx.sh
# USAGE:        Uncomment fxn calls in body as needed and execute without arguments.
#
# CREATED:      20150224 by stowler@gmail.com
# LAST UPDATED: see repo https://github.com/CVNRneuroimaging/proj.bh.volumetrics
#
# DESCRIPTION:
# This bare-bones script produces correlation maps (sufaces) showing the
# correlation between cortical thickness and Ben's measures of behavioral
# change.
#
# INPUT:
# Per-perticipant behavioral change values, and completed freesurfer reconstructions.
#
# OUTPUT: 
# Four .gii sufaces: anode and cathode correlations in LH and RH.
#
# SYSTEM REQUIREMENTS:
# afni, freesurfer
#




# ------------------------- START: define functions ------------------------- #


fxnRsyncToWorkstation(){
   # Due to variability in network and CPU resources, it can be useful to bring
   # all relevant files to a local workstation:

   mkdir -p $localSubjectsDir # ...which is a value from script body below

   rsync -vr --progress \
   stowler-local@pano.birc.emory.edu:/home/fs-localSubjects/fsaverage \
   ${localSubjectsDir}/

   rsync -vr --progress \
   stowler-local@pano.birc.emory.edu:/home/fs-localSubjects/SN* \
   ${localSubjectsDir}/
}

fxnRunQcache(){
   # Run qcache, as it wasn't run during original recon:
   # (takes about 15 minutes per subject)
    for blind in ${blinds}; do
       recon-all -s ${blind} -qcache
    done
} 

fxnPrepFsaverage(){
   # add SUMA directory to the freesurfer subject named fsaverage:
   @SUMA_Make_Spec_FS -use_mgz -sid fsaverage
}

fxnTestFsaverage(){
   # make sure that fsaverage's SUMA directory is working:
   cd ${SUBJECTS_DIR}/fsaverage/SUMA
   afni -niml &
   sleep 10
   suma -spec fsaverage_both.spec -sv fsaverage_SurfVol+orig &
   sleep 10
}

fxnCreateThicknessSurfaces(){
   # convert thickness surface files to gifti (.gii):
   for blind in ${blinds}; do
      for hem in lh rh; do
         mris_convert \
         -c ${SUBJECTS_DIR}/${blind}/surf/${hem}.thickness.fwhm10.fsaverage.mgh \
         ${SUBJECTS_DIR}/fsaverage/surf/${hem}.white \
         ${localOutDir}/${blind}.${hem}.thickness.fwhm10.fsaverage.gii
         # create a 4d bucket for each hemisphere:
         3dbucket \
         -prefix ${localOutDir}/${hem}.thickness.fwhm10.fsaverage.gii \
         ${localOutDir}/SN*${hem}.thickness.fwhm10.fsaverage.gii
      done
   done
}

fxnInspectThicknessSurfaces(){
   # inspect a sample left hemisphere from the thickness giftis:
   suma -spec $SUBJECTS_DIR/fsaverage/SUMA/fsaverage_lh.spec
   # ...then open SUMA's object controller, click "Load Dset" and load any of the left hems from $localOutDir
}

fxnConvertThicknessToNifti(){
   # convert thickness to volumes:
   # TBD: troubleshoot this for better across-participant registrations
   for blind in $blinds; do
      for hem in lh rh; do
         mri_surf2vol \
         --surfval $SUBJECTS_DIR/${blind}/surf/${hem}.thickness \
         --hemi ${hem} \
         --fillribbon \
         --template $SUBJECTS_DIR/${blind}/mri/orig.mgz \
         --volregidentity ${blind} \
         --outvol ${HOME}/${blind}_${hem}.ribbon.nii
      done
   done
}

fxnCorrAnode(){
   # The anode Bx data are the second column in the file provided by Ben (behaviorChange.txt[1] below):
   # NB: Weirdly $localOutDir is ignored by -prefix below, so must cd to it first:
   cp behaviorChange.txt $localOutDir/
   cd $localOutDir
   for hem in lh rh; do
      3dTcorr1D                                                \
      -spearman                                                \
      -prefix ${localOutDir}/${hem}_corr_spearman_anode.gii   \
      -ok_1D_text                                              \
      ${localOutDir}/${hem}.thickness.fwhm10.fsaverage.gii     \
      behaviorChange.txt[1]{1..$}
   done
}

fxnCorrCathode(){
   # The cathode Bx data are the third column in the file provided by Ben (behaviorChange.txt[2] below):
   # NB: Weirdly $localOutDir is ignored by -prefix, so must cd to it first:
   cp behaviorChange.txt $localOutDir/
   cd $localOutDir
   for hem in lh rh; do
      3dTcorr1D                                                \
      -spearman                                                \
      -prefix ${localOutDir}/${hem}_corr_spearman_cathode \
      -ok_1D_text                                              \
      ${localOutDir}/${hem}.thickness.fwhm10.fsaverage.gii     \
      behaviorChange.txt[2]{1..$}
   done
}

fxnInspectCorrSurfaces(){
   # Open two SUMA windows to interactively inspect the four correlation surfaces:
   suma \
   -spec $SUBJECTS_DIR/fsaverage/SUMA/fsaverage_lh.spec \
   -input ${localOutDir}/lh_corr_spearman_anode.gii ${localOutDir}/lh_corr_spearman_cathode.gii &

   suma \
   -spec $SUBJECTS_DIR/fsaverage/SUMA/fsaverage_rh.spec \
   -input ${localOutDir}/rh_corr_spearman_anode.gii ${localOutDir}/rh_corr_spearman_cathode.gii &
}


# ------------------------- FINISHED : define functions ------------------------- #


# ------------------------- START: define script constants ------------------------- #


# participant IDs:
blinds="SN002 SN003 SN004 SN005 SN006 SN007 SN009 SN011 SN012 SN014 SN016 SN018"

# a local directory, valid as a value for freesurfer's $SUBJECTS_DIR variable:
# (gets created and filled by fxnRsyncToWorkstation)
localSubjectsDir=/data/stowlerLocalOnly/bh/fs.SUBJECTS_DIR.SN
# ...and tell freesurfer to use it:
SUBJECTS_DIR=$localSubjectsDir

# a local directory for the script's output:
localOutDir=/data/stowlerLocalOnly/bh/SN.thickness
mkdir -p $localOutDir


# ------------------------- FINISHED: define script constants ------------------------- #


# ------------------------- START: body of script ------------------------- #


# Call this script's internal functions for all of the steps necessary to
# produce the final correlation maps:

#fxnRsyncToWorkstation
#fxnRunQcache
#fxnPrepFsaverage
#fxnTestFsaverage
#fxnCreateThicknessSurfaces
#fxnInspectThicknessSurfaces
#fxnCorrAnode
#fxnCorrCathode
#fxnInspectCorrSurfaces

# ------------------------- FINISHED: body of script ------------------------- #
