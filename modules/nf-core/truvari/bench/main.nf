process TRUVARI_BENCH {
    tag "$meta.id $meta2.caller"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/truvari:4.1.0--pyhdfd78af_0':
        'quay.io/biocontainers/truvari:4.1.0--pyhdfd78af_0' }"

    input:
    tuple val(meta),val(meta2), path(vcf), path(tbi), path(truth_vcf), path(truth_tbi), path(bed)
    tuple path(fasta), path(fai)

    output:
    tuple val(meta), path("*.fn.vcf.gz")            , emit: fn_vcf
    tuple val(meta), path("*.fn.vcf.gz.tbi")        , emit: fn_tbi
    tuple val(meta), path("*.fp.vcf.gz")            , emit: fp_vcf
    tuple val(meta), path("*.fp.vcf.gz.tbi")        , emit: fp_tbi
    tuple val(meta), path("*.tp-base.vcf.gz")       , emit: tp_base_vcf
    tuple val(meta), path("*.tp-base.vcf.gz.tbi")   , emit: tp_base_tbi
    tuple val(meta), path("*.tp-comp.vcf.gz")       , emit: tp_comp_vcf
    tuple val(meta), path("*.tp-comp.vcf.gz.tbi")   , emit: tp_comp_tbi
    tuple val(meta), path("*.summary.json")         , emit: summary
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def regions = bed ? "--includebed $bed" : ""
    def convert_type = params.dup_to_ins ? "--dup-to-ins" : ""

    """
    truvari bench \\
        --base ${truth_vcf} \\
        --comp ${vcf} \\
        --reference ${fasta} \\
        --output ${prefix} \\
        --pctseq $params.similarity \\
        $convert_type \\
        ${regions} \\
        ${args}

    mv ${prefix}/fn.vcf.gz          ./${prefix}.fn.vcf.gz
    mv ${prefix}/fn.vcf.gz.tbi      ./${prefix}.fn.vcf.gz.tbi
    mv ${prefix}/fp.vcf.gz          ./${prefix}.fp.vcf.gz
    mv ${prefix}/fp.vcf.gz.tbi      ./${prefix}.fp.vcf.gz.tbi
    mv ${prefix}/tp-base.vcf.gz     ./${prefix}.tp-base.vcf.gz
    mv ${prefix}/tp-base.vcf.gz.tbi ./${prefix}.tp-base.vcf.gz.tbi
    mv ${prefix}/tp-comp.vcf.gz     ./${prefix}.tp-comp.vcf.gz
    mv ${prefix}/tp-comp.vcf.gz.tbi ./${prefix}.tp-comp.vcf.gz.tbi
    mv ${prefix}/summary.json       ./${prefix}.summary.json

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        truvari: \$(echo \$(truvari version 2>&1) | sed 's/^Truvari v//' ))
    END_VERSIONS
    """
}
