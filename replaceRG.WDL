version 1.0
workflow FixHeader {
  input {
    Array[File] crams
	Array[String] sample_IDs
    String gatk_docker
  }
    scatter (scatter_index in range(length(crams))){
        call fix_header {
            input:
                input_cram = crams[scatter_index],
                sample_name = sample_IDs[scatter_index],
                docker = gatk_docker
        }
    }
    output {
        Array [String] source_samples = fix_header.source_sample
        Array [File] output_crams = fix_header.output_cram
		Array [String] source_crams = fix_header.source_cram
    }
}

task fix_header {
  input {
    # Command parameters
    File input_cram
    String sample_name

    # Runtime parameters
    String docker
    Int? machine_mem_gb
    Int? disk_space_gb
    Boolean use_ssd = false
    Int? preemptible_attempts
  }
    Int disk_size = ceil(size(input_cram, "GB") ) + 20
  
  command {
    set -e
    set -o pipefail

    samtools view -H ~{input_cram} > old_header.txt
    sed 's/\tSM:/\tPU:/g' old_header.txt > header_intermediate1.txt
    sed "s/$/\tSM:${sample_name}/g" header_intermediate1.txt > new_header.txt
    samtools reheader new_header.txt ~{input_cram} > "~{input_cram}.reheadered.cram"

  }
  runtime {
    docker: docker
    memory: select_first([machine_mem_gb, 15]) + " GB"
    disks: "local-disk " + select_first([disk_space_gb, disk_size]) + if use_ssd then " SSD" else " HDD"
    preemptible: select_first([preemptible_attempts, 3])
 }
  output {
    File output_cram = "~{sample_name}.crai"
    String source_cram = input_cram
    String source_sample = sample_name
  }
}
