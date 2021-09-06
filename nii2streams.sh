#!/bin/bash

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "" ]; then
  echo -e "\n	Usage: `basename $0` inline_roi (nifti) outline_roi (nifti) [side] [output_dir]"
  echo -e "\n	       Generates columnar & laminar cortical streamlines within"
  echo -e "\n	       the area between the provided ROIs."
  echo -e "\n	Returns: '*_out_resampled.tck' & '*_out_resampled_h.tck'.\n"
  exit 0
fi


#out_folder=${3:-$(dirname $grid_in)}

inline=$1
outline=$2
dir_name=${4:-`dirname $1`}
prefix=`${inline%%.*}`
side=${3:-"l"}

no_ext=`basename ${filename%%.*}` # {id}_{side}

IFS='_' read -ra my_array <<< "$no_ext"

prefix=39B; 
j=12
side=l # r  

#
./mask_closing.py 37A_l_inline.nii.gz 37A_l_outline.nii.gz

# Dilate cortical mask:
./mask_dilation.py ${prefix}_${side}_grid_mid.nii.gz 9


# Create grid for mincLaplace input:
./make_grid.sh ${prefix}_${side}_grid_in_short.nii.gz ${prefix}_${side}_grid_mid_dilatedx9.nii.gz


# Run 'mincLaplace' to generate `*_minc_thick_*.nii`:
./run_grid.sh ${prefix}_${side}_grid_123.mnc '_thick'


# Apply cortical mask `*_mid.nii.gz*` to `*_Grad[X-Z].nii`:
for a in GradX GradY GradZ RGB
do
	mrcalc ${prefix}_${side}_grid_mid.nii.gz ${prefix}_${side}_minc_thick_${a}.nii.gz -mult ${prefix}_${side}_minc_${a}.nii.gz
done

# Generate seed points for streamlines
./get_seeds.py ${prefix}_${side}_outline.nii.gz

# Create streamlines
mkdir $dir_name/tck

./vector2streams.py ${prefix}_${side}_minc_RGB.nii.gz ${prefix}_${side}_${j}_seeds_smooth_resampled.txt ~/Documentos/C13Lab/dysplasia_dataset/preproc/$prefix/ses-P30/dwi/${prefix}_mask_brain.nii.gz tck/${prefix}_${side}_${j}_out

# zip .txt files
tar -czvf tck/${prefix}_${side}_${j}_out.tar.gz tck/${prefix}_${side}_${j}_out_*.txt

# remove '*.txt'
rm tck/${prefix}_${side}_${j}_out_???.txt