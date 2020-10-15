
#nohup snakemake -s source_functions/snp_effects_ww.snakefile --latency-wait 90 --resources load=120 --jobs 10 --config --keep-going &> log/snakemake_log/200110.single_region.snp_effects_ww.log &

# conda install --yes mkl mkl-service

#export LD_LIBRARY_PATH=/home/agiintern/.conda/envs/regionsenv/lib

# install.packages("tidylog", repos="http://cran.r-project.org", lib= "~/R/x86_64-redhat-linux-gnu-library/3.6")

configfile: "source_functions/config/snp_effects_ww.config.yaml"

rule target:
    input:
        # targ = expand("data/derived_data/snp_effects_ww/3v{region}/snp_sol", region = config['region'])
        targ = expand("data/derived_data/snp_effects_ww/{region}_all/snp_sol", region = config['region'])

rule format_map:
    input:
        master_map = config['master_map']
    output:
        format_map = "data/derived_data/chrinfo.50k.txt"
    shell:
        """
        awk '{{print $5, $2, $3, $4}}' {input.master_map} &> {output.format_map}
        """
rule hp_sample:
    resources:
        load = 50
    input:
        fun_sample_until = "source_functions/sample_until.R",
        start_data = "data/derived_data/bootstrap_ww_start.rds",
    params:
        sample_limit = config['sample_limit']
    output:
        hp_zips = "data/derived_data/snp_effects_ww/hp_zips.csv"
    shell:
        "Rscript --vanilla source_functions/snp_effects_hp_sample.R {params.sample_limit} &> log/rule_log/hp_sample/hp_sample.log"


# Write out data files
# Create sampled datasets
rule sample:
    resources:
        load = 50
    input:
        fun_three_gen = "source_functions/three_gen.R",
        fun_sample_until = "source_functions/sample_until.R",
        start_data = "data/derived_data/bootstrap_ww_start.rds",
        ped = "data/derived_data/ped.rds",
        hp_zips = "data/derived_data/snp_effects_ww/hp_zips.csv"
    params:
        other_region = "{region}",
        sample_limit = config['sample_limit']
    output:
        # datafile = "data/derived_data/snp_effects_ww/3v{region}/data.txt",
        # pedfile = "data/derived_data/snp_effects_ww/3v{region}/ped.txt",
        # pullfile = "data/derived_data/snp_effects_ww/3v{region}/pull_genotypes.txt"
        datafile = "data/derived_data/snp_effects_ww/{region}_all/data.txt",
        pedfile = "data/derived_data/snp_effects_ww/{region}_all/ped.txt",
        pullfile = "data/derived_data/snp_effects_ww/{region}_all/pull_genotypes.txt"
    shell:
        # "Rscript --vanilla source_functions/snp_effects_ww_sample.R {params.sample_limit} {params.other_region} &> log/rule_log/snp_effects_ww_sample/sample.3v{params.other_region}.log"
        "Rscript --vanilla source_functions/one_region_sample.R {params.sample_limit} {params.other_region} &> log/rule_log/snp_effects_ww_sample/sample.{params.other_region}_all.log"

# Copy par files (BLUPF90)

rule initialize_blupf90:
    resources:
        load = 1
    input:
        # in_par = "data/derived_data/snp_effects_ww/bivariate_ww_blupf90.par"
        in_par = "data/derived_data/snp_effects_ww/univariate.par"
    output:
        # out_par = "data/derived_data/snp_effects_ww/3v{region}/bivariate_ww_blupf90.par"
        out_par = "data/derived_data/snp_effects_ww/{region}_all/univariate.par"
    shell:
        "cp {input.in_par} {output.out_par}"

# Left join genotypes in master genotype file to list of genotyped animals to be used
rule pull_genotypes:
    resources:
        load = 20
    input:
        # datafile = "data/derived_data/snp_effects_ww/3v{region}/data.txt",
        # pedfile = "data/derived_data/snp_effects_ww/3v{region}/ped.txt",
        # pullfile = "data/derived_data/snp_effects_ww/3v{region}/pull_genotypes.txt",
        # par = "data/derived_data/snp_effects_ww/3v{region}/bivariate_ww_blupf90.par"
        datafile = "data/derived_data/snp_effects_ww/{region}_all/data.txt",
        pedfile = "data/derived_data/snp_effects_ww/{region}_all/ped.txt",
        pullfile = "data/derived_data/snp_effects_ww/{region}_all/pull_genotypes.txt",
        par = "data/derived_data/snp_effects_ww/{region}_all/univariate.par"
    params:
        master_geno = config['master_geno']
    output:
        # reduced_geno = "data/derived_data/snp_effects_ww/3v{region}/genotypes.txt"
        reduced_geno = "data/derived_data/snp_effects_ww/{region}_all/genotypes.txt"
    shell:
        """
        grep -Fwf {input.pullfile} {params.master_geno} | awk '{{printf "%-25s %s\\n", $1, $2}}' &> {output.reduced_geno}
        """

rule renum_blupf90:
# make renf90.par & rename it
    resources:
        load = 20
    input:
        # input_par = "data/derived_data/snp_effects_ww/3v{region}/bivariate_ww_blupf90.par",
        # reduced_geno = "data/derived_data/snp_effects_ww/3v{region}/genotypes.txt",
        # datafile = "data/derived_data/snp_effects_ww/3v{region}/data.txt",
        # pedfile = "data/derived_data/snp_effects_ww/3v{region}/ped.txt",
        input_par = "data/derived_data/snp_effects_ww/{region}_all/univariate.par",
        reduced_geno = "data/derived_data/snp_effects_ww/{region}_all/genotypes.txt",
        datafile = "data/derived_data/snp_effects_ww/{region}_all/data.txt",
        pedfile = "data/derived_data/snp_effects_ww/{region}_all/ped.txt",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        # dir = "data/derived_data/snp_effects_ww/3v{region}"
        dir = "data/derived_data/snp_effects_ww/{region}_all"
    output:
        # blupf90_par = "data/derived_data/snp_effects_ww/3v{region}/renf90.blup.par"
        blupf90_par = "data/derived_data/snp_effects_ww/{region}_all/renf90.blup.par"
    shell:
        # """
        # cd {params.dir}
        # ~/bin/renumf90 bivariate_ww_blupf90.par &> renf90.blup.out
        # mv renf90.par renf90.blup.par
        # """
        """
        cd {params.dir}
        ~/bin/renumf90 univariate.par &> renf90.blup.out
        mv renf90.par renf90.blup.par
        """
#
rule blupf90:
    resources:
        load = 100
    input:
        # blupf90_par = "data/derived_data/snp_effects_ww/3v{region}/renf90.blup.par",
        blupf90_par = "data/derived_data/snp_effects_ww/{region}_all/renf90.blup.par",
        format_map = "data/derived_data/chrinfo.50k.txt"
    params:
        # dir = "data/derived_data/snp_effects_ww/3v{region}",
        # blupf90_out_name = "blupf90.3v{region}.out",
        dir = "data/derived_data/snp_effects_ww/{region}_all",
        blupf90_out_name = "blupf90.{region}_all.out",
        blupf90_path = config['blupf90_path']
    output:
        # blupf90_solutions = "data/derived_data/snp_effects_ww/3v{region}/solutions"
        blupf90_solutions = "data/derived_data/snp_effects_ww/{region}_all/solutions"
    shell:
        """
        cd {params.dir}
        {params.blupf90_path} renf90.blup.par &> {params.blupf90_out_name}
        """

# Copy postGSf90 par file
rule postGSf90_par:
    resources:
        load = 10
    input:
        # blupf90_solutions = "data/derived_data/snp_effects_ww/3v{region}/solutions",
        # blupf90_par = "data/derived_data/snp_effects_ww/3v{region}/renf90.blup.par"
        blupf90_solutions = "data/derived_data/snp_effects_ww/{region}_all/solutions",
        blupf90_par = "data/derived_data/snp_effects_ww/{region}_all/renf90.blup.par"
    params:
        # dir = "data/derived_data/snp_effects_ww/3v{region}"
        dir = "data/derived_data/snp_effects_ww/{region}_all"
    output:
        # postGSf90_par = "data/derived_data/snp_effects_ww/3v{region}/renf90.postgs.par"
        postGSf90_par = "data/derived_data/snp_effects_ww/{region}_all/renf90.postgs.par"
    shell:
        # """
        # head -n 39 {params.dir}/renf90.blup.par &> {params.dir}/renf90.postgs.par
        # cat data/derived_data/snp_effects_ww/postgsf90_options.txt >> {params.dir}/renf90.postgs.par
        # """
        """
        head -n 36 {params.dir}/renf90.blup.par &> {params.dir}/renf90.postgs.par
        cat data/derived_data/snp_effects_ww/postgsf90_options.txt >> {params.dir}/renf90.postgs.par
        """

rule postGSf90:
    resources:
        load = 100
    input:
        # blupf90_solutions = "data/derived_data/snp_effects_ww/3v{region}/solutions",
        # postGSf90_par = "data/derived_data/snp_effects_ww/3v{region}/renf90.postgs.par"
        blupf90_solutions = "data/derived_data/snp_effects_ww/{region}_all/solutions",
        postGSf90_par = "data/derived_data/snp_effects_ww/{region}_all/renf90.postgs.par"
    params:
        # dir = "data/derived_data/snp_effects_ww/3v{region}",
        # postGSf90_out_name = "postgsf90.3v{region}.out",
        dir = "data/derived_data/snp_effects_ww/{region}_all",
        postGSf90_out_name = "postgsf90.{region}_all.out",
        postGSf90_path = config['postGSf90_path']
    output:
        # snp_sol = "data/derived_data/snp_effects_ww/3v{region}/snp_sol"
        snp_sol = "data/derived_data/snp_effects_ww/{region}_all/snp_sol"
    shell:
        """
        cd {params.dir}
        {params.postGSf90_path} renf90.postgs.par &> {params.postGSf90_out_name}
        rm *.R
        rm *.gnuplot
        rm *pev*
        """
