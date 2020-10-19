# nohup snakemake -s source_functions/gwas_ww.gibbs.snakefile --keep-going --directory /home/agiintern/regions --rerun-incomplete --latency-wait 90 --resources load=120 -j 36 --until blupf90 --config &> log/snakemake_log/gwas_ww.gibbs/201019.gwas_ww.gibbs.log &

configfile: "source_functions/config/gwas_ww.gibbs.config.yaml"

os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/pull_list", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/make_par", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/setup_snp1101", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/create_grm", exist_ok = True)
os.makedirs("/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/snp1101", exist_ok = True)

rule target:
    input:
        expand("data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/solutions", iter = config['iter'], dataset = config['dataset']), expand("data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}/gwas_ssr_{effect}.txt", iter = config['iter'], dataset = config['dataset'], effect = config['effect']), expand("data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}/gwas_ssr_{effect}_p.txt", iter = config['iter'], dataset = config['dataset'], effect = config['effect'])

rule format_map:
    input:
        master_map = config['master_map']
    output:
        format_map = "data/derived_data/chrinfo.50k.txt"
    shell:
        """
        awk '{{print $5, $2, $3, $4}}' {input.master_map} &> {output.format_map}
        """

rule pull_list:
    input:
        ped = "data/derived_data/varcomp_ww/iter{iter}/3v1/gibbs/ped.txt",
        genotyped = "data/raw_data/genotyped_animals.txt",
        script = "source_functions/pull_geno.gwas_ww.gibbs.R"
    params:
        iter = "{iter}"
    output:
        pull_list = "data/derived_data/gwas_ww.gibbs/iter{iter}/pull_list.txt"
    shell:
        "Rscript --vanilla {input.script} {params.iter} &> log/rule_log/gwas_ww.gibbs/pull_list/pull_list.iter{params.iter}.log"

# Left join genotypes in master genotype file to list of genotyped animals to be used
rule pull_genotypes:
    resources:
        load = 30
    input:
        pull_list = "data/derived_data/gwas_ww.gibbs/iter{iter}/pull_list.txt"
    params:
        master_geno = config['master_geno']
    output:
        reduced_geno = "data/derived_data/gwas_ww.gibbs/iter{iter}/genotypes.txt"
    shell:
        """
        grep -Fwf {input.pull_list} {params.master_geno} | awk '{{printf "%-25s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

# Generate BLUPF90 parameter file
rule make_par:
    input:
        script = "source_functions/write_blupf90_par.bivariate.R",
        postmean = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/postmean",
        base_par = "source_functions/par/blupf90.bivariate.par"
    params:
        iter = "{iter}",
        dataset = "{dataset}"
    output:
        par_out = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/blupf90.par"
    shell:
        "Rscript --vanilla {input.script} {params.iter} {params.dataset} &> log/rule_log/gwas_ww.gibbs/make_par/make_par.iter{params.iter}.{params.dataset}.log"

rule copy_genotypes:
    input:
        reduced_geno = "data/derived_data/gwas_ww.gibbs/iter{iter}/genotypes.txt"
    output:
        moved_geno = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/genotypes.txt"
    shell:
        "cp {input.reduced_geno} {output.moved_geno}"

rule copy_data:
    input:
        data = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/data.txt",
        ped = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/ped.txt"
    output:
        moved_data = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/data.txt",
        moved_ped = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/ped.txt"
    shell:
        """
        cp {input.data} {output.moved_data}
        cp {input.ped} {output.moved_ped}
        """

rule renum_blupf90:
    input:
        moved_data = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/data.txt",
        moved_ped = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/ped.txt",
        moved_geno = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/genotypes.txt",
        in_par = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/blupf90.par",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        renumf90_path = config['renumf90_path'],
        directory = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}",
        in_par = "blupf90.par",
        renum_out = "renf90.blup.iter{iter}.{dataset}.out"
    output:
        renum_par = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/renf90.par"
    shell:
        """
        cd {params.directory}
        {params.renumf90_path} {params.in_par} &> {params.renum_out}
        """

# Use BLUPF90 to calculate breeding values, to be de-regressed in SNP1101 for GWAS
rule blupf90:
    resources:
        load= 40
    input:
        renum_par = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/renf90.par",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        dir = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}",
        blupf90_out = "blupf90.iter{iter}.{dataset}.out",
        blupf90_path = config['blupf90_path']
    output:
        blupf90_solutions = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/solutions"
    shell:
        """
        cd {params.dir}
        {params.blupf90_path} renf90.par &> {params.blupf90_out}
        """

rule create_grm:
    input:
        reduced_geno = "data/derived_data/gwas_ww.gibbs/iter{iter}/genotypes.txt",
        grm_ctr = "/home/agiintern/regions/source_functions/par/grm.ctr",
        snp1101_map = "data/derived_data/snp1101_map.txt"
    params:
        snp1101_path = config['snp1101_path'],
        dir = "data/derived_data/gwas_ww.gibbs/iter{iter}",
        log = "/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/create_grm/create_grm.iter{iter}.log"
    output:
        grm = "data/derived_data/gwas_ww.gibbs/iter{iter}/out/gmtx_grm.bin",
        grm_ctr = "data/derived_data/gwas_ww.gibbs/iter{iter}/out/grm_ctr.txt",
        report = "data/derived_data/gwas_ww.gibbs/iter{iter}/out/report.txt"
    shell:
        """
        cd {params.dir}
        {params.snp1101_path} {input.grm_ctr} &> {params.log}
        """

rule setup_snp1101:
    input:
        blupf90_solutions = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/solutions",
        script = "source_functions/setup_snp1101_bivariate.R"
    params:
        iter = "{iter}",
        dataset = "{dataset}"
    output:
        trait_maternal = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/trait_maternal.txt",
        trait_direct = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/trait_direct.txt"
    shell:
        "Rscript {input.script} {params.iter} {params.dataset} &> log/rule_log/gwas_ww.gibbs/setup_snp1101/setup_snp1101.iter{params.iter}.{params.dataset}.log"

rule copy_ctr:
    input:
        ctr_in = "source_functions/par/{effect}.ctr"
    output:
        ctr_out = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}.ctr"
    shell:
        "cp {input.ctr_in} {output.ctr_out}"

rule snp1101:
    input:
        ctr = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}.ctr",
        grm = "data/derived_data/gwas_ww.gibbs/iter{iter}/out/gmtx_grm.bin",
        trait = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/trait_{effect}.txt"
    params:
        dir = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/",
        snp1101_path = config['snp1101_path'],
        ctr = "{effect}.ctr",
        snp1101_log = "/home/agiintern/regions/log/rule_log/gwas_ww.gibbs/snp1101/snp1101.iter{iter}.{dataset}.{effect}.log"
    output:
        test = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/test_{effect}.txt",
        p_val = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}/gwas_ssr_{effect}_p.txt",
        stats = "data/derived_data/gwas_ww.gibbs/iter{iter}/{dataset}/{effect}/gwas_ssr_{effect}.txt"
    shell:
        """
        cd {params.dir}
        cat {output.test}
        {params.snp1101_path} {params.ctr} &> {params.snp1101_log}
        """
