# Lab 5: QPSK Modulation and Demodulation

## Due NLT 6 Nov (Lesson 32) by 2359 on Gradescope

## Overview

So far we've looked at AM and FM signals and completed some basic GNU Radio Companion tutorials to help us better understand filtering and sample rates. In this lab we will shift to a digital modulation technique called Differential Quadrature Phase Shift Keying (DQPSK). We will again use one of the tutorials from the GNU Radio Wiki page. This tutorial walks you through most of the communication chain from source to sink, with a special emphasis on signal distortion and channel impairments. You have been learning about ISI and timing errors in the past few lessons. In this lab you will implement a system that incorporates those errors _and_ ways to address them. You will also use eye diagrams to subjectively evaluate the system's effectiveness.

## Aims of the Lab

The goals of this lab are to:
    
- Understand why signal distortion (e.g., inter-symbol interference, or ISI) occurs and how to counter it.
- Understand channel effects on a signal and how to accurately recover the signal at the receiver.
- Provide experience using eye diagrams.

## DQPSK Communication System

Navigate to the tutorial at this link: https://wiki.gnuradio.org/index.php?title=QPSK_Mod_and_Demod. You will work through thsi tutorial to build a "complete" system from bits, to transmitted waveform through a channel, to a receiver accomplishing time synchronization and equalization, to decoding, and back to bits again. As you work through the tutorial, make sure you read everything and build the flowgraph from scratch for practice (don't just download the completed product!). Also, you must accomplish the following additional tasks and answer the following questions.

1. In the Constellation Modulator hierarchical block, there is a parameter called Excess Bandwidth. This is equivalent to the roll-off factor $r$ we learned about in class. Because the block uses extra samples per symbol, you divide the sample rate $R_b$ by the number of samples/symbol to get a symbol rate $R_s$. Then you can use $R_s$ just like we would use $R_b$ in the textbook to find total transmit bandwidth $B_T$ (Eq. 6.33 in the textbook). 

    Calculate $B_T$ for each of the five excess bandwidth values used in the Excess Bandwidth section of the tutorial. Do your results match what is shown in the tutorial's QT GUI Plot? Include the answers in your lab write up.

2. What is an RRC filter? Where do we use it in the communication system described in the tutorial? Why?

3. List the three channel impairments added by the Channel Model block.

4. When you get to the Polyphase Clock Sync block, jump down to the **Using the Symbol Sync block** section at the bottom of the tutorial. Click on the [Symbol_Sync](https://wiki.gnuradio.org/index.php?title=Symbol_Sync) hyperlink to read through the 4 functions the block performs.

5. Jump back to just after the Polyphase Clock Sync section, and pick up where you left off with the Multipath section.

6. Note how the flowgraph uses Virtual Sink and Virtual Source to make the flowgraph cleaner and easy to follow. 

7. Why does the constellation diagram at the output of the equalizer look like a circle instead of the four, distinct symbols we started off with?

8. The Costas Loop is a PLL (phase locked loop)-based circuit used for carrier frequency recovery and is especially useful for DSB-SC or phase modulated signals.

9. After the Constellation Decoder, Differential Decoder, and Map, you are ready to unpack your received bits. The flowgraph provided in the tutorial graphically displays the received bits (Data 0) with the transmitted bits (Data 1). Do the two perfectly line up? Why not? What value of delay leads to perfect alignment? (Hint: it isn't what the tutorial says it is!)

10. Insert a QT GUI Eye Sink and connect it to the Costas Loop output. Set Samples per Symbol to 1 and turn on the Autoscale. Run your flowgraph and see how changing the Noise Voltage, Timing Offset, and Frequency Offset affects the eye in your diagram. 

    - Change the values for time_offset to start at 0.7 and stop at 1.1 in increments of 0.01. What do you notice about the system performance as you sweep through these time offset values? 
    - Return the noise and time offset values back to their original values. Now just change the frequency offset values. At what frequency offset value (plus or minus) does your eye completely close?
    - Comment on the importance of time and frequency synchronization in a digital communication system.

11. Include a screenshot of your final flowgraph in your writeup.

12. Summarize in a short paragraph what Dr. Rogers covered in class.

## Lab Report

Submit a neat, single PDF to Gradescope addressing all of the questions and directions listed above.


