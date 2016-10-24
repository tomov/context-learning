# for training trials
./optseq2 --ntp 100 --tr 2 --tprescan 0 --psdwin 0 12 --ev x1c1 4 5 --ev x2c1 4 5 --ev x1c2 4 5 --ev x2c2 4 5 --nsearch 10000 --nkeep 270 --sumdelays --mtx par/itis_train --log par/itis_train --o par/itis_train --tnullmin 2 --tnullmax 12

# for test trials
#./optseq2 --ntp 24 --tr 2 --tprescan 0 --psdwin 0 10 --ev x1c1 6 1 --ev x3c1 6 1 --ev x1c3 6 1 --ev x3c3 6 1 --nsearch 10000 --nkeep 270 --sumdelays --mtx par/itis_test --log par/itis_test --o par/itis_test --tnullmin 2 --tnullmax 12

