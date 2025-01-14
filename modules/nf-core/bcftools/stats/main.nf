process BCFTOOLS_STATS {
    tag "$meta.id $meta2.caller"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.18--h8b25389_0':
        'quay.io/biocontainers/bcftools:1.18--h8b25389_0' }"

    input:
    tuple val(meta), val(meta2), path(vcf), path(index)
    tuple val(meta3), path(regions)
    tuple val(meta4), path(targets)
    tuple val(meta5), path(samples)
    tuple val(meta6), path(exons)
    tuple val(meta7), path(fasta)

    output:
    tuple val(meta),val(meta2), path("*stats.txt"), emit: stats
    path  "versions.yml"                          , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def regions_file = regions ? "--regions-file ${regions}" : ""
    def targets_file = targets ? "--targets-file ${targets}" : ""
    def samples_file =  samples ? "--samples-file ${samples}" : ""
    def reference_fasta = fasta ? "--fasta-ref ${fasta}" : ""
    def exons_file = exons      ? "--exons ${exons}" : ""
    """
    bcftools stats \\
        $args \\
        $regions_file \\
        $targets_file \\
        $samples_file \\
        $reference_fasta \\
        $exons_file \\
        $vcf > ${prefix}.bcftools_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}.bcftools_stats.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
