# nohup snakemake -s source_functions/varcomp_ww.snakefile --keep-going --directory /home/agiintern/regions --rerun-incomplete --latency-wait 90 --resources load=120 -j 24 --config --until gibbs &> log/snakemake_log/varcomp_ww/200908.varcomp_ww.log &

import os

# Make log directories if they don't exist
os.makedirs("/home/agiintern/regions/log/rule_log/varcomp_ww", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/varcomp_ww/sample", exist_ok = True)

configfile: "source_functions/config/varcomp_ww.yaml"

rule all:
    input:
        expand("data/derived_data/varcomp_ww/iter{iter}/{dataset}/{file}", iter = config['iter'], dataset = config['dataset'], file = ["postout", "postmean"])

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
        load = 20
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
        pull_list = expand("data/derived_data/varcomp_ww/iter{{iter}}/{dataset}/pull_list.txt", dataset = config['dataset']),
        summary = "data/derived_data/varcomp_ww/iter{iter}/varcomp_ww.data_summary.iter{iter}.csv"
    shell:
        "Rscript --vanilla {input.script} {params.iter} &> log/rule_log/varcomp_ww/sample/sample.iter{params.iter}.log"

# Copy par file for tworegion datasets
rule copy_par:
    resources:
        load = 1
    input:
        in_par = lambda wildcards: expand("source_functions/par/varcomp_ww.{analysis}.par", analysis = config['dataset_key'][wildcards.dataset])
    output:
        out_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/varcomp_ww.par"
    shell:
        "cp {input.in_par} {output.out_par}"

# Left join genotypes in master genotype file to list of genotyped animals to be used
rule pull_genotypes:
    resources:
        load = 20
    input:
        datafile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/data.txt",
        pedfile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/ped.txt",
        pullfile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/pull_list.txt"
    params:
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/genotypes.txt"
    shell:
        """
        grep -Fwf {input.pullfile} {params.master_geno} | awk '{{printf "%-25s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renf90:
    resources:
        load = 1
    input:
        in_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/varcomp_ww.par",
        reduced_geno = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/genotypes.txt",
        datafile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/data.txt",
        pedfile = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/ped.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}",
        renum_out = "renf90.iter{iter}.{dataset}.out"
    output:
        renum_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.par",
        renum_out = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.iter{iter}.{dataset}.out"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} varcomp_ww.par &> {params.renum_out}
        """

rule gibbs:
    resources:
        load = 10
    input:
        renum_par = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.par",
        renum_out = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/renf90.iter{iter}.{dataset}.out"
    params:
        gibbs_path = config['gibbs_path'],
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}",
        rounds = config['rounds'],
        burnin = config['burnin'],
        thin = config['thin'],
        gibbs_out = "gibbs.iter{iter}.{dataset}.out",
        psrecord = "/home/agiintern/regions/log/psrecord/varcomp_ww/gibbs/gibbs.iter{iter}.{dataset}.log"
    output:
        last_solutions = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/last_solutions"
    shell:
        """
        cd {params.directory}
        psrecord "{params.gibbs_path} renf90.par --rounds {params.rounds} --burnin {params.burnin} --thin {params.thin} --thinprint {params.thin} &> {params.gibbs_out}" --log {params.psrecord} --include-children --interval 5
        """

rule post_gibbs:
    resources:
        load = 10
    input:
        last_solutions = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/last_solutions"
    params:
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}",
    output:
        postout = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/postout",
        postmean = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/postmean"
    # All integer arguments need to be strings in yaml config file in order to run
    run:
        import pexpect
        child = pexpect.spawn(config['post_gibbs_path'] + ' renf90.par', cwd = params.directory)
        child.expect('Burn-in?')
        child.sendline(config['post_gibbs_burnin'])
        child.expect('Give n to read')
        child.sendline(config['thin'])
        child.expect('Choose a graph for samples')
        child.sendline('0')
