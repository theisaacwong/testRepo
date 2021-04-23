workflow CopyFile{
    Array[File] gvcfs
	Array[String] sample_IDs
	
    File? gatk4_jar_override
    String gatk_docker

    scatter (scatter_index in range(length(gvcfs))){
        call CopyFile {
            input:
                gvcf = gvcfs[scatter_index],
				sample_ID = sample_IDs[scatter_index],
                gatk4_jar_override = gatk4_jar_override,
                gatk_docker = gatk_docker,
        }
    }

    output {
        Array [String] sample = CopyFile.entity_id
        Array [File] copied_gvcf = CopyFile.copied_gvcf
    }
}

task CopyFile {
    File gvcf
    File? gatk4_jar_override
	String sample_ID

    # Runtime parameters
    String gatk_docker
    Int? disk_space_gb
    Boolean use_ssd = false
    Int cpu=1
    Int? preemptible_attempts

    Int machine_mem_mb = 600
    Int command_mem_mb = machine_mem_mb - 100

    String copied_gvcf = "${sample_ID}.copy.​vcf.​gz"
	
    command <<<
        set -euo pipefail
		cp ${gvcf} ${copied_gvcf}
    >>>

    runtime {
        docker: "${gatk_docker}"
        memory: machine_mem_mb + " MB"
        disks: "local-disk " + select_first([disk_space_gb, ceil(size(gvcf, "GB")) + 5]) + if use_ssd then " SSD" else " HDD"
        cpu: select_first([cpu, 1])
        preemptible: select_first([preemptible_attempts, 5])
        maxRetries: 3
    }

    output {
        String entity_id = sample_ID
        File copied_gvcf = copied_gvcf
    }
}


