#!/bin/bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "" ]; then
  echo -e "\n	Usage: `basename $0` inline_roi (nifti) outline_roi (nifti)"
  echo -e "\n	       Generates columnar & laminar cortical streamlines within"
  echo -e "\n	       the area between the provided ROIs."
  echo -e "\n	Returns: '*_out_resampled.tck' & '*_out_resampled_h.tck'.\n"
  exit 0
fi

rat_id=39B; 
j=12
side=l # r  

#
./mask_closing.py 37A_l_inline.nii.gz 37A_l_outline.nii.gz

# Dilate cortical mask:
./mask_dilation.py ${rat_id}_${side}_grid_mid.nii.gz 9


# Create grid for mincLaplace input:
./make_grid.sh ${rat_id}_${side}_grid_in_short.nii.gz ${rat_id}_${side}_grid_mid_dilatedx9.nii.gz


# Run 'mincLaplace' to generate `*_minc_thick_*.nii`:
./run_grid.sh ${rat_id}_${side}_grid_123.mnc '_thick'


# Apply cortical mask `*_mid.nii.gz*` to `*_Grad[X-Z].nii`:
for a in GradX GradY GradZ RGB
do
	mrcalc ${rat_id}_${side}_grid_mid.nii.gz ${rat_id}_${side}_minc_thick_${a}.nii.gz -mult ${rat_id}_${side}_minc_${a}.nii.gz
done

# Generate seed points for streamlines
./get_seeds.py ${rat_id}_${side}_outline.nii.gz

# Create streamlines
mkdir tck

./vector2streams.py ${rat_id}_${side}_minc_RGB.nii.gz ${rat_id}_${side}_${j}_seeds_smooth_resampled.txt ~/Documentos/C13Lab/dysplasia_dataset/preproc/$rat_id/ses-P30/dwi/${rat_id}_mask_brain.nii.gz tck/${rat_id}_${side}_${j}_out