# nohup snakemake -s source_functions/varcomp_ww.snakefile --keep-going --directory /home/agiintern/regions --rerun-incomplete --latency-wait 90 --resources load=160 -j 24 --config &> log/snakemake_log/varcomp_ww/201008.varcomp_ww.log &

import os

# Make log directories if they don't exist
os.makedirs("/home/agiintern/regions/log/rule_log/varcomp_ww", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/varcomp_ww/sample", exist_ok = True)

configfile: "source_functions/config/varcomp_ww.yaml"

rule all:
    input:
     expand("data/derived_data/varcomp_ww/iter{iter}/{dataset}/airemlf90.iter{iter}.{dataset}.log", iter = config['iter'], dataset = config['dataset']), expand("data/derived_data/varcomp_ww/iter{iter}/genotypes.iter{iter}.txt", iter = config['iter'])

# Format map file for BLUPF90
rule format_map:
    input:
        master_map = config['master_map']
    output:
        format_map = "data/derived_data/chrinfo.50k.txt"
    shell:
        """
        awk '{{print $5, $2, $3, $4}}' {input.master_map} &> {output.format_map}
        """

# Create sample datasets
rule sample:
    resources:
        load = 40
    input:
        fun_three_gen = "source_functions/three_gen.R",
        fun_sample_until = "source_functions/sample_until.R",
        fun_ped = "source_functions/ped.R",
        fun_write_data = "source_functions/write_tworegion_data.R",
        region_key = "source_functions/region_key.R",
        script = "source_functions/varcomp_ww_start.R",
        ww_data = "data/derived_data/varcomp_ww/ww_data.rds",
        ped = "data/derived_data/import_regions/ped.rds"
    params:
        iter = "{iter}"
    output:
        datafile = expand("data/derived_data/varcomp_ww/iter{{iter}}/{dataset}/data.txt", dataset = config['dataset']),
        pedfile = expand("data/derived_data/varcomp_ww/iter{{iter}}/{dataset}/ped.txt", dataset = config['dataset']),
        pull_list = "data/derived_data/varcomp_ww/iter{iter}/pull_list.txt",
        summary = "data/derived_data/varcomp_ww/iter{iter}/varcomp_ww.data_summary.iter{iter}.csv"
    shell:
        "Rscript --vanilla {input.script} {params.iter} &> log/rule_log/varcomp_ww/sample/sample.iter{params.iter}.log"

# Copy par file for tworegion datasets
rule copy_par:
    resources:
        load = 20
    input:
        in_par = "source_functions/par/varcomp_ww.tworegion.par"
    output:
        out_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/varcomp_ww.par"
    shell:
        "cp {input.in_par} {output.out_par}"

# Left join genotypes in master genotype file to list of genotyped animals to be used
rule pull_genotypes:
    resources:
        load = 30
    input:
        pullfile = "data/derived_data/varcomp_ww/iter{iter}/pull_list.txt"
    params:
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/varcomp_ww/iter{iter}/genotypes.iter{iter}.txt"
    shell:
        """
        grep -Fwf {input.pullfile} {params.master_geno} | awk '{{printf "%-25s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renf90:
    resources:
        load = 20
    input:
        in_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/varcomp_ww.par",
        datafile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/data.txt",
        pedfile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/ped.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}",
        renum_out = "renf90.iter{iter}.{dataset}.out"
    output:
        renum_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.par"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} varcomp_ww.par &> {params.renum_out}
        """

rule aireml:
    resources:
        load = lambda wildcards: config['resources_key'][wildcards.dataset]
    input:
        renum_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.par"
    params:
        aireml_path = config['airemlf90_path'],
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}",
        aireml_out = "aireml.iter{iter}.{dataset}.out",
        aireml_renamed = "airemlf90.iter{iter}.{dataset}.log"
    output:
        aireml_renamed = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/airemlf90.iter{iter}.{dataset}.log"
    shell:
        """
        cd {params.directory}
        ulimit -S -s unlimited
        ulimit -H -s unlimited
        {params.aireml_path} renf90.par &> {params.aireml_out}
        mv airemlf90.log {params.aireml_renamed}
        """