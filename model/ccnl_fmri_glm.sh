# single subject GLM
#

mkdir output

for model in {1..17}
do
        for i in {1..25}
        do
            sbatch -p ncf --mem 50000 -t 20-18:20 -o output/ccnl_fmri_glm_"$model"_subj_"$i"_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $'ccnl_fmri_glm(contextExpt(), $model, [$i]);exit'"
        done
done

#sbatch -p ncf --mem 50000 -t 20-18:20 -o fmri_glm_job_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $'ccnl_fmri_glm(contextExpt(), 1, [25]);exit'"
