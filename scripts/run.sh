#!/bin/bash

source "$(dirname "$0")/config.sh"

SCRIPT_DIR="$LOCAL_PROJECT_DIR/scripts"
NAME_FILE="$SCRIPT_DIR/names.txt"
SUBMIT_SCRIPT="$SCRIPT_DIR/submit.sh"
NAMD_DIR="$HPC_PROJECT_DIR/NAMD_2.14_Linux-x86_64-multicore"
POLYMERS_DIR="$HPC_PROJECT_DIR/polymers"

generate_script() {
    mapfile -t polymer_names < "$NAME_FILE"
    simulations=${#polymer_names[@]}

    case "$HPC" in
        mike)
            tasks=4
            cores=16
            gres="gpu:4"
            partition="gpu"
            account="hpc_hpc_tyw_01"
            ;;
        loni)
            if [ "$simulations" -eq 4 ]; then
                tasks=4
                cores=16
                gres="gpu:4"
                partition="gpu4"
                account="loni_poly_surf"
            elif [ "$simulations" -eq 2 ]; then
                tasks=2
                cores=32
                gres="gpu:2"
                partition="gpu2"
                account="loni_poly_surf"
            else
                exit
            fi
            ;;
        *)
            exit
            ;;
    esac

    cat << EOF > "$SUBMIT_SCRIPT"
#!/bin/bash
#SBATCH -N 1
#SBATCH -n $tasks
#SBATCH --cpus-per-task=$cores
#SBATCH --gres=$gres
#SBATCH -t 72:00:00
#SBATCH -p $partition
#SBATCH -A $account
#SBATCH -o /dev/null

module load cuda
EOF

    for poly_name in "${polymer_names[@]}"; do
        cat << EOF >> "$SUBMIT_SCRIPT"
srun --ntasks=1 --gres=gpu:1 --cpus-per-task=$cores \\
     "$NAMD_DIR/namd2" \\
     +p16 "$POLYMERS_DIR/${poly_name}/20sim/20_waterbox.conf" \\
     > "$POLYMERS_DIR/${poly_name}/20sim/output.log" &
EOF
    done
    
    echo -e "\nwait" >> "$SUBMIT_SCRIPT"
}

submit() {
    case "$HPC" in
        mike)
            ssh "${USER}@mike.hpc.lsu.edu" "sbatch $HPC_PROJECT_DIR/scripts/submit.sh"
            ;;
        loni)
            ssh "${USER}@qbd.loni.org" "sbatch $HPC_PROJECT_DIR/scripts/submit.sh"
            ;;
    esac
}

main() {
    if [ ! -f "$NAME_FILE" ]; then
        exit
    fi
    generate_script
    #submit
    rm "$NAME_FILE"
}
main