# nohup snakemake -s source_functions/calculate_blups.snakefile --directory /home/agiintern/angus_regions --rerun-incomplete --latency-wait 30 --resources load=40 -j 24 --config &> log/snakemake_log/calculate_blups/210226.calculate_blups.log &

configfile: "source_functions/config/calculate_blups.config.yaml"

rule all:
    input:
     expand("data/derived_data/calculate_blups/{dataset}/solutions", dataset = config['dataset'])

rule setup:
    resources:
        load = 1
    input:
        last_solutions = lambda wildcards: expand("data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/last_solutions", dataset = wildcards.dataset, iter = config['iter']),
        base_par = "source_functions/par/calculate_blups.par",
        script = "source_functions/setup.calculate_blups.R",
        postmean = lambda wildcards: expand("data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/postmean", dataset = wildcards.dataset, iter = config['iter'])
    params:
        dataset = "{dataset}",
        rule_log = "log/rule_log/calculate_blups/setup/setup.{dataset}.log"
    output:
        par = "data/derived_data/calculate_blups/{dataset}/calculate_blups.par",
        data = "data/derived_data/calculate_blups/{dataset}/data.txt",
        ped = "data/derived_data/calculate_blups/{dataset}/ped.txt"
    shell:
        "Rscript --vanilla {input.script} {params.dataset} &> {params.rule_log}"

rule renf90:
    resources:
        load = 20
    input:
        par = "data/derived_data/calculate_blups/{dataset}/calculate_blups.par",
        data = "data/derived_data/calculate_blups/{dataset}/data.txt",
        ped = "data/derived_data/calculate_blups/{dataset}/ped.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/calculate_blups/{dataset}",
        renum_out = "renf90.{dataset}.out"
    output:
        renum_par = "data/derived_data/calculate_blups/{dataset}/renf90.par"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} calculate_blups.par &> {params.renum_out}
        """

rule blup:
    resources:
        load = 40
    input:
        renum_par = "data/derived_data/calculate_blups/{dataset}/renf90.par"
    params:
        blupf90_path = config['blupf90_path'],
        directory = "data/derived_data/calculate_blups/{dataset}",
        blup_out = "blup.{dataset}.out"
    output:
        solutions = "data/derived_data/calculate_blups/{dataset}/solutions"
    shell:
        """
        cd {params.directory}
        ulimit -s unlimited
        export OMP_NUM_THREADS=12
        {params.blupf90_path} renf90.par &> {params.blup_out}
        """
