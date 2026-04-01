version 1.0

task Bench {
  input {
    File comp_vcf_gz
    File comp_vcf_gz_tbi
    File base_vcf_gz
    File base_vcf_gz_tbi
    File base_bed
    File ref_fa
    Int num_cpus = 32
  }

  command <<<
    ln -s ~{comp_vcf_gz} .
    ln -s ~{comp_vcf_gz_tbi} .
    ln -s ~{base_vcf_gz} .
    ln -s ~{base_vcf_gz_tbi} .

    /usr/bin/time -v \
      truvari bench \
        -b ~{basename(base_vcf_gz)} \
        -c ~{basename(comp_vcf_gz)} \
        -f ~{ref_fa} \
        --includebed ~{base_bed} \
        -O 0.0 -r 1000 -p 0.0 -P 0.3 -C 1000 -s 50 -S 15 --sizemax 100000 --pick ac --no-ref c \
        -o out

    /usr/bin/time -v \
      truvari refine \
        -t ~{num_cpus} \
        out \
        --align mafft \
        --use-original-vcfs
  >>>

  output {
    File tp_base_vcf_gz = "out/tp-base.vcf.gz"
    File tp_base_vcf_gz_tbi = "out/tp-base.vcf.gz.tbi"
    File tp_comp_vcf_gz = "out/tp-comp.vcf.gz"
    File tp_comp_vcf_gz_tbi = "out/tp-comp.vcf.gz.tbi"
    File fp_vcf_gz = "out/fp.vcf.gz"
    File fp_vcf_gz_tbi = "out/fp.vcf.gz.tbi"
    File fn_vcf_gz = "out/fn.vcf.gz"
    File fn_vcf_gz_tbi = "out/fn.vcf.gz.tbi"
    File summary = "out/summary.json"
    File refine_base_vcf_gz = "out/refine.base.vcf.gz"
    File refine_base_vcf_gz_tbi = "out/refine.base.vcf.gz.tbi"
    File refine_comp_vcf_gz = "out/refine.comp.vcf.gz"
    File refine_comp_vcf_gz_tbi = "out/refine.comp.vcf.gz.tbi"
    File refine_region_summary = "out/refine.region_summary.json"
    File refine_variant_summary = "out/refine.variant_summary.json"
  }

  runtime {
    cpu: num_cpus
    memory: "64 GB"
    docker: "quay.io/biocontainers/truvari:5.4.0--pyhdfd78af_0"
  }
}
