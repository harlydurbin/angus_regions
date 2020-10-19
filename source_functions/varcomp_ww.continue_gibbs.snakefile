# nohup snakemake -s source_functions/varcomp_ww.continue_gibbs.snakefile --keep-going --directory /home/agiintern/regions --rerun-incomplete --latency-wait 90 --resources load=180 -j 24 --config --until gibbs_continue &> log/snakemake_log/varcomp_ww.gibbs/201014.varcomp_ww.gibbs.continue.log &

import os

configfile: "source_functions/config/varcomp_ww.gibbs.config.yaml"

rule all:
    input:
     expand("data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/{file}", iter = config['iter'], dataset = config['dataset'], file = ["postout", "postmean", "done.txt"])

rule update_par:
    input:
        binary_sol = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/binary_final_solutions",
        renf90 = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/renf90.par"
    output:
        renf90_cont = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/renf90.continue.par"
    shell:
        """
        cp {input.renf90} {output.renf90_cont}
        echo -e 'OPTION cont 1' >> {output.renf90_cont}
        """

rule gibbs_continue:
    resources:
        load = 5
    input:
        renf90_cont = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/renf90.continue.par"
    params:
        gibbs_path = config['gibbs_path'],
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs",
        rounds = config['continue_rounds'],
        burnin = config['burnin'],
        thin = config['thin'],
        gibbs_out = "gibbs.continue.iter{iter}.{dataset}.out"
    output:
        last_solutions = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/last_solutions",
        done = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/done.txt"
    shell:
        """
        cd {params.directory}
        echo -e 'renf90.continue.par \\n {params.rounds} {params.burnin} \\n {params.thin}' | {params.gibbs_path} &> {params.gibbs_out}
        echo 'done' > done.txt
        """

rule post_gibbs:
    resources:
        load = 10
    input:
        last_solutions = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/last_solutions",
        done = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/done.txt"
    params:
        directory = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs",
    output:
        postout = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/postout",
        postmean = "data/derived_data/varcomp_ww/iter{iter}/{dataset}/gibbs/postmean"
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
