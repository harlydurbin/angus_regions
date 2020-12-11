# nohup snakemake -s source_functions/defunct/bivariate_bootstrap.snakefile --keep-going --rerun-incomplete --latency-wait 90 --resources load=200 -j 24 --config --until initialize &> log/snakemake_log/bivariate_bootstrap/201118.bivariate_bootstrap.log &

configfile: "source_functions/config/bivariate_bootstrap.config.yaml"

rule all:
    input:
        expand("data/derived_data/bootstrap_ww/3v{region}/iter{iter}/airemlf90.iter{iter}_3v{region}.log", region = config['region'], iter = config['iter'])

# Create sample datasets
rule sample:
    resources:
        load = 50
    input:
        fun_three_gen = "source_functions/three_gen.R",
        fun_sample_until = "source_functions/sample_until.R",
        start_data = "data/derived_data/varcomp_ww/ww_data.rds",
        #ped = "data/derived_data/ped.rds"
    params:
        iter = "{iter}",
        other_region = "{region}"
    output:
        datafile = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/data.txt",
        pedfile = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/ped.txt"
    shell:
        "Rscript --vanilla source_functions/defunct/bootstrap_ww_sample.R {params.iter} {params.other_region} &> log/rule_log/bivariate_bootstrap/sample/sample.iter{params.iter}_3v{params.other_region}.log"

# Copy par file
rule initialize:
    resources:
        load = 1
    input:
        in_par = "data/derived_data/bootstrap_ww/bootstrap_ww.par",
        datafile = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/data.txt",
    output:
        out_par = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/bootstrap_ww.par"
    shell:
        "cp {input.in_par} {output.out_par}"

rule renf90:
    resources:
        load = 25
    input:
        in_par = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/bootstrap_ww.par",
        ped = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/ped.txt",
        data = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/data.txt"
    params:
        directory = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}",
        renum_out = "renf90.iter{iter}_3v{region}.out"
    output:
        renum_par = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/renf90.par",
        renum_out = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/renf90.iter{iter}_3v{region}.out"
    shell:
        """
        cd {params.directory}
        /usr/local/bin/renumf90 bootstrap_ww.par &> {params.renum_out}
        """

rule bootstrap_aireml:
    resources:
        load = 100
    input:
        renum_par = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/renf90.par",
        renum_out = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/renf90.iter{iter}_3v{region}.out"
    params:
        directory = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}",
        aireml_out = "aireml.iter{iter}_3v{region}.out",
        aireml_renamed = "airemlf90.iter{iter}_3v{region}.log"
    output:
        aireml_renamed = "data/derived_data/bootstrap_ww/3v{region}/iter{iter}/airemlf90.iter{iter}_3v{region}.log"
    shell:
        # """
        # cd {params.directory}
        # ulimit -s unlimited
        # ~/bin/airemlf90 renf90.par &> {params.aireml_out} && mv {params.aireml_log} {output.aireml_renamed}
        # """
        """
        cd {params.directory}
        ulimit -S -s unlimited
        ulimit -H -s unlimited
        ~/bin/airemlf90 renf90.par &> {params.aireml_out}
        mv airemlf90.log {params.aireml_renamed}
        """
