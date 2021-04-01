# nohup snakemake -s source_functions/post_gibbs.snakefile --directory /home/agiintern/angus_regions --rerun-incomplete --latency-wait 90 --resources load=50 --config &> log/snakemake_log/post_gibbs/210330.post_gibbs.log &

configfile: "source_functions/config/post_gibbs.config.yaml"

rule all:
    input:
     expand("data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/{file}", iter = config['iter'], dataset = config['dataset'], file = ["postout", "postmean", "postgibbs_samples"])

rule post_gibbs:
    resources:
        load = 10
    input:
        solutions = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/binary_final_solutions"
    params:
        directory = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}",
    output:
        postout = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/postout",
        postmean = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/postmean",
        postgibbs_samples = "data/derived_data/gibbs_varcomp/iter{iter}/{dataset}/postgibbs_samples"
    # All integer arguments need to be strings in yaml config file in order to run
    run:
        import pexpect
        child = pexpect.spawn(config['post_gibbs_path'] + ' renf90.par', cwd = params.directory)
        child.expect('Burn-in?')
        child.sendline(config['post_gibbs_burnin'])
        child.expect('Give n to read')
        child.sendline(config['post_gibbs_thin'])
        child.expect('Choose a graph for samples')
        child.sendline('0')
