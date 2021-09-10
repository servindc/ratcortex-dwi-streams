#!/bin/bash

help()
{
  reset="\e[0m" # reset color
  color="\e[1;33m" # yellow
  echo -e "\n      ${color}Usage:${reset} `basename $0` inline_roi outline_roi ref_image [side] [out_dir]"
  echo -e "\n       ${color}Info:${reset} Generates columnar & laminar cortical streamlines within"
  echo -e "             the area between the provided ROIs."
  echo -e "\n ${color}Parameters:${reset} inline_roi - Cortical inline (nifti format)"
  echo -e "             outline_roi - Interior (nifti format)"
  echo -e "             ref_image - reference subject image to get the affine transform (nifti format)"
  echo -e "             side - hemisphere side of the given ROIs"
  echo -e "             out_dir - Output dirctory (default = 'inline_roi' directory)"
  echo -e "\n    ${color}Returns:${reset} '*_out_resampled.tck' & '*_out_resampled_h.tck' streamlines files.\n"
}

if [ "$1" == "-h" -o "$1" == "--help" -o "$1" == "" ]; then help; exit 0; fi


#out_folder=${3:-$(dirname $grid_in)}

inline=$1
outline=$2
ref_image=$3
side=${4:-"l"}
dir_name=${5:-`dirname $inline`} # output directory
no_ext=`basename ${inline%%.*}` # 'inline_roi' basename without file extension
prefix=${no_ext::-9} # 'inline_roi' subject ID with path
script_dir=`dirname $0`

# print parameters
echo -e "\n    Parameters: " $inline $outline $ref_image $side $dir_name $prefix $script_dir"\n"

#prefix=39B; 
#j=12
#side=l # r  

# Masks construction:
echo -e "\n  Running: mask_closing.py $inline $outline"
$script_dir/mask_closing.py $inline $outline

# Dilate cortical mask (9 pixels):
input1=$dir_name/${prefix}_${side}_grid_mid.nii.gz; voxels_dilated=9
echo -e "\n  Running: mask_dilation.py ${input1} $voxels_dilated"
$script_dir/mask_dilation.py $input1 $voxels_dilated

# Create grid for mincLaplace input:
input1=$dir_name/${prefix}_${side}_grid_in_short.nii.gz
input2=$dir_name/${prefix}_${side}_grid_mid_dilatedx${voxels_dilated}.nii.gz
echo -e "\n  Running: make_grid.sh $input1 $input2"
$script_dir/make_grid.sh $input1 $input2


# Run 'mincLaplace' to generate `*_minc_thick_*.nii`:
input1=$dir_name/${prefix}_${side}_grid_123.mnc
echo -e "\n  Running: run_grid.sh $input1 '_thick'"
$script_dir/run_grid.sh $input1 '_thick'

# Apply cortical mask `*_mid.nii.gz*` to `*_Grad[X-Z].nii`:
input1=$dir_name/${prefix}_${side}_grid_mid.nii.gz
for a in GradX GradY GradZ RGB
do
  input2=$dir_name/${prefix}_${side}_minc_thick_${a}.nii.gz
  output=$dir_name/${prefix}_${side}_minc_${a}.nii.gz
  echo -e "\n  Applying cortical mask '$input1' to '$input2':"
	mrcalc $input1 $input2 -mult $output
done


# Generate seed points for streamlines
input1=$dir_name/${prefix}_${side}_outline.nii.gz
echo -e "\n  Running: get_seeds.py $input1"
$script_dir/get_seeds.py $input1; exit 0

# Create streamlines
mkdir $dir_name/tck

$script_dir/vector2streams.py ${prefix}_${side}_minc_RGB.nii.gz ${prefix}_${side}_${j}_seeds_smooth_resampled.txt ~/Documentos/C13Lab/dysplasia_dataset/preproc/$prefix/ses-P30/dwi/${prefix}_mask_brain.nii.gz tck/${prefix}_${side}_${j}_out

# zip .txt files
tar -czvf tck/${prefix}_${side}_${j}_out.tar.gz tck/${prefix}_${side}_${j}_out_*.txt

# remove '*.txt'
rm tck/${prefix}_${side}_${j}_out_???.txt