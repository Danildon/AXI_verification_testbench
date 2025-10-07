#  Set path for current stimuli file 
set CURRENT_STIMULI_PATH ./../Current_Stimuli.txt 

set STIMULI_DIR_PATH ./../Stimuli 
#  Set path for Current report file 

#      [file exists ./../TESTBENCH/Current_Stimuli.txt]         ./../TESTBENCH/Current_Stimuli.txt

set CURRENT_REPORT_PATH ./../Current_Report.txt

cd $STIMULI_DIR_PATH

set stimuli_files [glob $STIMULI_DIR_PATH -type f *{Test}*]
cd ./../Scripts


puts $stimuli_files
set test_n [llength $stimuli_files]

puts "We have $test_n to execute in the Stimuli folder"
set stim_files [regexp -all -inline -- {[0-9]+} $stimuli_files ]

foreach index $stim_files {
    set sim_num $index

    puts "we are starting sim n $sim_num"
    source ./simulate_one.tcl
}