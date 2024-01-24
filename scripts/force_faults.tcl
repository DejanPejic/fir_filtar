set time_step 1000
set time_end 10000
set fir_ord 5
set red_num 5 
set critical 3

# Self-Rurging Redundancy sistem koji se sastoji od red_num modula moze da tolerise red_num - 2 greske
# Siguran rad sistema (forsiranje red_num - 2 greske)
for {set x 0} {$x < $red_num - 2} {incr x 1} {
	# biranje signala kojem se forsira vrijednost
	set force_path /fir_axi_top_tb/duv/self_purging_fir/mac_inter[$fir_ord][$x]
	
	# biranje momenta pocetka forsiranja vrijednosti
	set time_force_begin $time_step
    set begin_string [append time_force_begin ns]
    
	# biranje momenta zavrsavanja forsiranja vrijednosti
	set time_force_end $time_end
    set end_string [append time_force_end ns]
    
    add_force $force_path -radix hex fffffffff $begin_string -cancel_after $end_string

    incr time_step 1000
}

# Dodavanje kriticne greske - dobija se pogrijesna vrijednost na izlazu koja se znacajno razlikuje od ocekivane, sto dovodi do pada simulacije
set x $critical
set force_path /fir_axi_top_tb/duv/self_purging_fir/mac_inter[$fir_ord][$x]

set time_force_begin $time_step
set begin_string [append time_force_begin ns]

set time_force_end $time_end
set end_string [append time_force_end ns]

add_force $force_path -radix hex fffffffff $begin_string -cancel_after $end_string