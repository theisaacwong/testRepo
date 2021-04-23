workflow bamToUBam {

    File picardJar
    Array[File] inputBams
    Array[String] entity_ids
	File gatk_docker

    scatter (sample_index in range(length(entity_ids))) {
        call revertSam {
            input:
			    picardJar = picardJar,	
                entity_id = entity_ids[sample_index],
                inputBam = inputBams[sample_index],
				gatk_docker = gatk_docker
        }
    }
    output{
	    Array[File] ubamOutput = revertSam.ubamOutput
	}
}

task revertSam {
    File picardJar
    File inputBam
    String entity_id
	String gatk_docker
  
    command {
      java -jar ${picardJar} \
   	    RevertSam \
        I=${inputBam} \
        O=${entity_id}.unmapped.bam \
        SANITIZE=true \
        MAX_DISCARD_FRACTION=0.005 \
        ATTRIBUTE_TO_CLEAR=XT \
        ATTRIBUTE_TO_CLEAR=XN \
        ATTRIBUTE_TO_CLEAR=AS \
        ATTRIBUTE_TO_CLEAR=OC \
        ATTRIBUTE_TO_CLEAR=OP \
        SORT_ORDER=queryname \
        RESTORE_ORIGINAL_QUALITIES=true \
        REMOVE_DUPLICATE_INFORMATION=true \
        REMOVE_ALIGNMENT_INFORMATION=true \
        VALIDATION_STRINGENCY=SILENT
    }
	
	runtime {
        docker: "${gatk_docker}"
        memory: "10GB"
        disks: "local-disk " + "200" + " HDD"
        cpu: 1
        preemptible: 4
    }
	
    output {
      File ubamOutput = "${entity_id}.unmapped.bam"
    }
}