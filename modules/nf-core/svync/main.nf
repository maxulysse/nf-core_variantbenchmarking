process SVYNC {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/svync:0.1.2--h9ee0642_0':
        'quay.io/biocontainers/svync:0.1.2--h9ee0642_0' }"

    input:
    tuple val(meta),val(meta2), path(vcf), path(tbi), path(config)

    output:
    tuple val(meta),val(meta2), path("*.vcf.gz"), path("*.vcf.gz.tbi"), emit: vcf
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args   = task.ext.args ?: ''
    def args2  = task.ext.args2 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    if ("$vcf" == "${prefix}.vcf.gz") error "Input and output names are the same, set prefix in module configuration to disambiguate!"

    """
    svync \\
        $args \\
        --config $config \\
        --input $vcf \\
        | bgzip --threads $task.cpus $args2 > ${prefix}.vcf.gz

    tabix ${prefix}.vcf.gz
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        svync: \$(svync --version | sed 's/svync version //')
    END_VERSIONS
    """
}
