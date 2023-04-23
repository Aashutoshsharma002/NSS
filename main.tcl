#Create a new simulation object
set ns [new Simulator]

#Create a new topology object
set topo [new Topography]

#Create nodes in the network
set node0 [$ns node]
set node1 [$ns node]
set node2 [$ns node]
set node3 [$ns node]

#Set the position of nodes in the network
$node0 set X_ 0.0
$node0 set Y_ 0.0
$node1 set X_ 500.0
$node1 set Y_ 0.0
$node2 set X_ 0.0
$node2 set Y_ 500.0
$node3 set X_ 500.0
$node3 set Y_ 500.0

#Create a wireless interface and set its properties
$ns node-config -adhocRouting DSDV \
                 -llType LL \
                 -macType Mac/802_11 \
                 -ifqType Queue/DropTail/PriQueue \
                 -ifqLen 50 \
                 -antType OmniAntenna \
                 -propType Propagation/TwoRayGround \
                 -phyType Phy/WirelessPhy \
                 -channel Channel/WirelessChannel \
                 -topoInstance $topo \
                 -agentTrace ON \
                 -routerTrace ON \
                 -macTrace ON \
                 -movementTrace ON
                 
#Create a wireless link between nodes
$ns duplex-link $node0 $node1 2Mb 10ms DropTail
$ns duplex-link $node1 $node3 2Mb 10ms DropTail
$ns duplex-link $node3 $node2 2Mb 10ms DropTail
$ns duplex-link $node2 $node0 2Mb 10ms DropTail

#Create a new traffic source
set traffic [new Application/Traffic/CBR]
$traffic set packetSize_ 500
$traffic set interval_ 0.005
$traffic set random_ false

#Create a new traffic sink
set sink [new Agent/LossMonitor]

#Attach the traffic source to node0
$ns attach-agent $node0 $traffic

#Attach the traffic sink to node3
$ns attach-agent $node3 $sink

#Connect the traffic source and the sink
$ns connect $traffic $sink

#Create a trace file for the simulation
set tracefile [open wireless.tr w]
$ns trace-all $tracefile

#Define simulation parameters
$ns node-config -addressType hierarchical

#Set the simulation time
set simtime 10.0

#Run the simulation with different routing protocols
set protocols {DSDV AODV DSR}
foreach p $protocols {
    $ns at 0.0 "$ns rtproto $p"
    $ns at 0.5 "$traffic start"
    $ns at $simtime "$traffic stop"
    $ns at $simtime "$ns halt"
    $ns run
    
    #Parse the trace file to extract performance metrics
    set f [open wireless.tr r]
    set data [read $f]
    close $f
    
    set delay [expr [lindex [split [lindex [split $data "\n"] end-1] " "] 3]*1000]
    set throughput [expr [lindex [split [lindex [split $data "\n"] end-2] " "] 7]/$simtime]
    set packetdelivery [expr [lindex [split [lindex [split $data "\n"] end-3] " "] 7]*100]
    set packetloss [expr [lindex [split [lindex [split $data "\n"] end-3] " "] 10]*100]
    
    #Print the performance metrics for each routing protocol
    puts "Performance metrics for $p protocol:"
    puts "Packet delivery fraction = $packetdelivery%"
    puts "Packet loss fraction = $packetloss%"
    puts "Average end-to-end delay = $delay ms"
    puts "Throughput = $throughput bps"
    puts ""
}

#Close the trace file
close $tracefile

#Terminate the simulation
$ns halt
$ns delete```
