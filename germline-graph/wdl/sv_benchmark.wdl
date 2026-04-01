version 1.0

################################################################################
# workflow SvBenchmark

workflow SvBenchmark {
  input {
    File comp_vcf_gz
    File comp_vcf_gz_tbi
    File base_vcf_gz
    File base_vcf_gz_tbi
    File base_bed
    File ref_fa
  }

  call ReformatVcf {
    input:
    vcf_gz = comp_vcf_gz
  }

  call Truvari {
    input:
    comp_vcf_gz = ReformatVcf.reformat_vcf_gz,
    comp_vcf_gz_tbi = ReformatVcf.reformat_vcf_gz_tbi,
    base_vcf_gz = base_vcf_gz,
    base_vcf_gz_tbi = base_vcf_gz_tbi,
    base_bed = base_bed,
    ref_fa = ref_fa
  }

  output {
    File tp_base_vcf_gz = Truvari.tp_base_vcf_gz
    File tp_base_vcf_gz_tbi = Truvari.tp_base_vcf_gz_tbi
    File tp_comp_vcf_gz = Truvari.tp_comp_vcf_gz
    File tp_comp_vcf_gz_tbi = Truvari.tp_comp_vcf_gz_tbi
    File fp_vcf_gz = Truvari.fp_vcf_gz
    File fp_vcf_gz_tbi = Truvari.fp_vcf_gz_tbi
    File fn_vcf_gz = Truvari.fn_vcf_gz
    File fn_vcf_gz_tbi = Truvari.fn_vcf_gz_tbi
    File summary = Truvari.summary
    File refine_base_vcf_gz = Truvari.refine_base_vcf_gz
    File refine_base_vcf_gz_tbi = Truvari.refine_base_vcf_gz_tbi
    File refine_comp_vcf_gz = Truvari.refine_comp_vcf_gz
    File refine_comp_vcf_gz_tbi = Truvari.refine_comp_vcf_gz_tbi
    File refine_region_summary = Truvari.refine_region_summary
    File refine_variant_summary = Truvari.refine_variant_summary
  }
}

################################################################################
# task ReformatVcf

task ReformatVcf {
  input {
    File vcf_gz
  }

  String vcf_basename = '~{basename(vcf_gz, ".vcf.gz")}'

  command <<<
    gunzip -c ~{vcf_gz} | \
      sed -e "s/GRCh38#0#//" | \
      bcftools norm -m-any -O z -W=tbi -o ~{vcf_basename}.reformat.vcf.gz
  >>>

  output {
    File reformat_vcf_gz = "~{vcf_basename}.reformat.vcf.gz"
    File reformat_vcf_gz_tbi = "~{vcf_basename}.reformat.vcf.gz.tbi"
  }

  runtime {
    memory: "16 GB"
    docker: "quay.io/biocontainers/bcftools:1.23--h3a4d415_0"
  }
}

################################################################################
# task Truvari

task Truvari {
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
