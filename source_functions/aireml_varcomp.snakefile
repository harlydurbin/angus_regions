# nohup snakemake -s source_functions/aireml_varcomp.snakefile --directory /home/agiintern/angus_regions --rerun-incomplete --latency-wait 30 --resources load=200 -j 24 --config &> log/snakemake_log/aireml_varcomp/210225.aireml_varcomp.log &

configfile: "source_functions/config/aireml_varcomp.config.yaml"

rule all:
    input:
     expand("data/derived_data/aireml_varcomp/iter{iter}/{dataset}/airemlf90.iter{iter}.{dataset}.log", iter = config['iter'], dataset = config['dataset'])

rule setup_par:
    resources:
        load = 1
    input:
        last_solutions = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/last_solutions",
        base_par = "source_functions/par/aireml_varcomp.par",
        script = "source_functions/setup.aireml_varcomp.R",
        postmean = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/postmean"
    params:
        iter = "{iter}",
        dataset = "{dataset}",
        rule_log = "log/rule_log/aireml_varcomp/setup_par/setup_par.iter{iter}.{dataset}.log"
    output:
        par = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/aireml_varcomp.par"
    shell:
        "Rscript --vanilla {input.script} {params.iter} {params.dataset} &> {params.rule_log}"

# Copy par file for tworegion datasets
rule copy_data:
    resources:
        load = 20
    input:
        ped = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/ped.txt",
        data = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/data.txt"
    output:
        ped = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/ped.txt",
        data = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/data.txt"
    shell:
        """
        cp {input.ped} {output.ped}
        cp {input.data} {output.data}
        """

rule renf90:
    resources:
        load = 20
    input:
        par = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/aireml_varcomp.par",
        data = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/data.txt",
        ped = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/ped.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}",
        renum_out = "renf90.iter{iter}.{dataset}.out"
    output:
        renum_par = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/renf90.par"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} aireml_varcomp.par &> {params.renum_out}
        """

rule aireml:
    resources:
        load = 50
    input:
        renum_par = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/renf90.par"
    params:
        aireml_path = config['airemlf90_path'],
        directory = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}",
        aireml_out = "aireml.iter{iter}.{dataset}.out",
        aireml_renamed = "airemlf90.iter{iter}.{dataset}.log"
    output:
        aireml_renamed = "data/derived_data/aireml_varcomp/iter{iter}/{dataset}/airemlf90.iter{iter}.{dataset}.log"
    shell:
        """
        cd {params.directory}
        export OMP_NUM_THREADS=6
        {params.aireml_path} renf90.par &> {params.aireml_out}
        mv airemlf90.log {params.aireml_renamed}
        """
