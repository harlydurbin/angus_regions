# nohup snakemake -s source_functions/gwas_ww.gibbs.snakefile --keep-going --directory /home/agiintern/regions --rerun-incomplete --latency-wait 90 --resources load=120 -j 36 --until blupf90 --config &> log/snakemake_log/gwas_ww.gibbs/201026.gwas_ww.gibbs.log &

configfile: "source_functions/config/gwas_ww.gibbs.config.yaml"

os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/make_par", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/setup_blupf90", exist_ok = True)

rule target:
    input:
        expand("data/derived_data/gwas_ww.gibbs/{dataset}/solutions", dataset = config['dataset'])

rule format_map:
    input:
        master_map = config['master_map']
    output:
        format_map = "data/derived_data/chrinfo.50k.txt"
    shell:
        """
        awk '{{print $5, $2, $3, $4}}' {input.master_map} &> {output.format_map}
        """

rule setup_blupf90:
    input:
        data = expand("data/derived_data/varcomp_ww/iter{iter}/{{dataset}}/gibbs/data.txt", iter = config['iter']),
        script = "source_functions/setup_blupf90.bivariate.R",
        genotyped = "data/raw_data/genotyped_animals.txt",
        ww_data = "data/derived_data/varcomp_ww/ww_data.rds",
        ped = "data/derived_data/import_regions/ped.rds"
    params:
        dataset = "{dataset}"
    output:
        data = "data/derived_data/gwas_ww.gibbs/{dataset}/data.txt",
        ped = "data/derived_data/gwas_ww.gibbs/{dataset}/ped.txt",
        pull_list = "data/derived_data/gwas_ww.gibbs/{dataset}/pull_list.txt"
    shell:
        "Rscript --vanilla {input.script} {params.dataset} &> log/rule_log/gwas_ww.gibbs/setup_blupf90/setup_blupf90.{params.dataset}.log"

# Left join genotypes in master genotype file to list of genotyped animals to be used
rule pull_genotypes:
    resources:
        load = 30
    input:
        pull_list = "data/derived_data/gwas_ww.gibbs/{dataset}/pull_list.txt"
    params:
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/gwas_ww.gibbs/{dataset}/genotypes.txt"
    shell:
        """
        grep -Fwf {input.pull_list} {params.master_geno} | awk '{{printf "%-25s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

# Generate BLUPF90 parameter file
rule make_par:
    input:
        script = "source_functions/write_blupf90_par.bivariate.R",
        postmean = expand("data/derived_data/varcomp_ww/iter{iter}/{{dataset}}/gibbs/postmean", iter = config['iter']),
        in_par = "source_functions/par/blupf90.bivariate.par"
    params:
        dataset = "{dataset}"
    output:
        par_out = "data/derived_data/gwas_ww.gibbs/{dataset}/blupf90.par"
    shell:
        "Rscript --vanilla {input.script} {params.dataset} &> log/rule_log/gwas_ww.gibbs/make_par/make_par.{params.dataset}.log"

rule renum_blupf90:
    input:
        data = "data/derived_data/gwas_ww.gibbs/{dataset}/data.txt",
        ped = "data/derived_data/gwas_ww.gibbs/{dataset}/ped.txt",
        reduced_geno = "data/derived_data/gwas_ww.gibbs/{dataset}/genotypes.txt",
        in_par = "data/derived_data/gwas_ww.gibbs/{dataset}/blupf90.par",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/gwas_ww.gibbs/{dataset}",
        in_par = "blupf90.par",
        renum_out = "renf90.blup.{dataset}.out"
    output:
        renum_par = "data/derived_data/gwas_ww.gibbs/{dataset}/renf90.par"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} {params.in_par} &> {params.renum_out}
        """

# Use BLUPF90 to calculate breeding values for eventual ssGWAS
rule blupf90:
    resources:
        load = 40
    input:
        renum_par = "data/derived_data/gwas_ww.gibbs/{dataset}/renf90.par",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        dir = "data/derived_data/gwas_ww.gibbs/{dataset}",
        blupf90_out = "blupf90.{dataset}.out",
        blupf90_path = config['blupf90_path']
    output:
        blupf90_solutions = "data/derived_data/gwas_ww.gibbs/{dataset}/solutions"
    shell:
        """
        cd {params.dir}
        {params.blupf90_path} renf90.par &> {params.blupf90_out}
        """
