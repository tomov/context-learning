for run in {1..9}
do
    runs="[1:$((run - 1)) $((run + 1)):9]"

    echo leave out run $run

    #sbatch -p ncf --mem 250000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('mask.nii', 'condition', [1:19], 1:9, [20:20], 1:9);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('hippocampus.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('ofc.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('striatum.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('vmpfc.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('rlpfc.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('bg.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
    sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify4('pallidum.nii', 'condition', [1:24], $runs, [1:24], $run);   exit\""
done



#sbatch -p ncf --mem 250000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('mask.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('hippocampus.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('ofc.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('striatum.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('vmpfc.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('rlpfc.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('bg.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""
#sbatch -p ncf --mem 25000 -t 20-18:20 -o classify_%j_output.out --mail-type=END --wrap="matlab -nodisplay -nosplash -nojvm -r $\"classify2('pallidum.nii', 'condition', [1:19], 1:9, [1:1], 1:9);   exit\""

