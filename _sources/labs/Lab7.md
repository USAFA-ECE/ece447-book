# Lab 7: Digital Wireless System using MATLAB

### Due to Gradescope NLT 2359 on Thursday, 4 Dec (L40)

## Overview

We have be covering binary digital communication systems in class. We have also discussed QAM, frequency division multiplexing, channel noise, and random signals. This lab is a conglomeration of all of these topics and shows how modern wireless telecommunication systems achieve high performance in challenging environments.

You will first complete an online MATLAB tutorial for wireless communications. This tutorial will explain concepts and walk you through the necessary code. You will need your Mathworks login info to complete the tutorial. After that, you will use a provided MATLAB script to plot the BER vs. SNR for varying levels of QAM signals, both with and without multipath in the channel. Next, you will use a different MATLAB script to plot the BER vs. SNR for QAM signals using Orthogonal Frequency Division Multiplexing (OFDM). You will see how knowledge of the channel, or the CSI, can drastically improve digital system performance.

## Aims of the Lab

The purposes of this lab are: 
- Explore the impact of noise and multipath on QAM signals.
- Understand how OFDM and Channel State Information (CSI) affect system performance.

## Introduction

Wireless communication systems face significant challenges due to the nature of the radio channel. One of the most critical impairments is multipath propagation, which occurs when transmitted signals reflect off buildings, terrain, and other objects, arriving at the receiver via multiple paths. These delayed copies of the signal interfere with each other, causing fading and distortion that degrade system performance. Multipath effects become more pronounced in high-data-rate systems, where symbol durations are short and inter-symbol interference (ISI) can severely impact reliability.

To combat multipath, modern systems employ Orthogonal Frequency Division Multiplexing (OFDM). OFDM divides the available bandwidth into many narrow subcarriers, each carrying a portion of the data. By transmitting symbols in parallel across these subcarriers, OFDM converts a frequency-selective channel into multiple flat-fading channels, greatly reducing ISI. This technique is widely used in standards such as LTE, Wi-Fi, and 5G because it improves robustness in multipath environments.

Historically, OFDM emerged in the late 1960s as a theoretical concept for mitigating multipath in high-speed data transmission. It gained practical relevance in the 1980s with digital broadcasting and DSL technologies, where its ability to handle severe channel impairments proved invaluable. The breakthrough came in the 1990s when OFDM was adopted for wireless LANs (IEEE 802.11a) and later became the foundation for 4G LTE and 5G NR. Its efficiency in spectrum usage and resilience to multipath made it the dominant modulation technique for modern broadband wireless systems.

Another key concept in wireless systems is Channel State Information (CSI). CSI represents the transmitter’s and receiver’s knowledge of the channel characteristics. Accurate CSI enables techniques like adaptive modulation, coding, and equalization, which optimize performance under varying conditions. When CSI is imperfect—due to measurement errors or outdated estimates—system performance degrades, especially in multipath channels. Understanding the impact of CSI quality is essential for designing resilient communication systems.

In this lab, you will explore these concepts by simulating QAM signals under different conditions, comparing performance with and without OFDM, and analyzing the role of CSI. Through MATLAB-based experiments, you will gain insight into how modern wireless systems mitigate multipath and why accurate channel knowledge is critical for reliable communication.

## Part 1: MATLAB Wireless Communications Onramp Tutorial

Complete the tutorial located at this link:

https://matlabacademy.mathworks.com/details/wireless-communications-onramp/wireless

The time required to complete the tutorial is estimated to be one hour, so plan accordingly.

## Part 2: Bit Error Rate (BER) vs. Signal-to-Noise Ratio (SNR) for QAM Signals

In the next part of this lab, you will use what you learned in the tutorial to investigate the effect of noise and multipath on QAM signals. Use this MATLAB code: [WCO_Lab_QAM.m](WCO_Lab_QAM.m) (generated from the tutorial online). Complete the following steps and answer the questions for your lab report:

1. Plot the BER versus the SNR for 4-, 16-, 64-, and 256-QAM over SNRs ranging from -20 dB to 40 dB in increments of at most 2 dB for a regular AWGN channel without multipath.
    
    a. Copy and paste the plot into your lab report. 
    
    b. This plot is known as a _waterfall plot_ due to its shape. A system can be designed to dynamically change the modulation format after measuring the SNR of the channel to maintain a specific BER. Using your plot, estimate how many extra decibels in SNR each additional bit in the QAM symbol achieves to maintain a BER of $10^{-3}$. For example, 4-QAM uses 2 bits and 16-QAM uses 4 bits. At BER = $10^{-3}$, estimate the difference between the SNRs of the two QAM formats. (Note: smaller SNR increments make this easier.)

2. Modify the code to include multipath in the channel and generate a plot with the same QAM modulation orders and SNRs as before.

    a. Copy and paste the plot into your document.

    b. How is this plot different than the first one? Why?

3. With the multipath option enabled, MATLAB should generate a spectrum analyzer plot showing the transmitted signal in yellow and the channel in blue in the frequency domain. How does what you see in the plot explain the differences between your first two plots? (Hint: Part 4 of the online tutorial – Multipath Channels - discusses this in the Further Practice section.)


## Part 3: BER vs. SNR for QAM Symbols using OFDM in a Multipath Environment

In this part of the lab, you will investigate the effect of noise and multipath on QAM signals *using OFDM*. You will also look at how having less than perfect Channel State Information (CSI) at the transmitter affects the system’s performance. Use this MATLAB code: [WCO_Lab_OFDM.m](WCO_Lab_OFDM.m). Complete the following steps and add your plots and answers to your lab report:

1. Plot the BER versus the SNR for 4-, 16-, 64-, and 256-QAM over SNRs ranging from -20 dB to 40 dB in increments of at most 2 dB for a regular AWGN channel with multipath using OFDM and with perfect CSI knowledge at the transmitter (Option 1 selected).

    a. Copy and paste the plot into your lab report.

    b. How does this plot compare to the multipath plot in Part 2 that did not use OFDM? Why does OFDM improve the communication system’s performance when multipath is present?

2. Perfect CSI enables perfect equalization at the receiver. If the CSI is corrupted, whether through incorrect channel sounding or other means, the system performance degrades.
    - In Option 2, only a single path of the multipath CSI is corrupted.
    - In Option 3, each path of the multipath vector has a small amount of noise added to it.
    - In Option 4, the receiver does not have any CSI.

    Re-run the code for each option and save the plots.

    a. Copy and paste the plots into your document.

    b. Compare and contrast the three plots with imperfect CSI (Options 2–4) to the plot with perfect CSI (Option 1) at the receiver. Discuss the impact of having good CSI at the receiver to system performance. How does the performance compare between Options 2 and 3 (one corrupt path vs. all paths slightly corrupted)? What happens if you increase the amplitude of the noise corrupting the CSI (currently set to 0.05)?

## Lab Report

- Complete the Mathworks Wireless Communications On-ramp tutorial at:
https://matlabacademy.mathworks.com/details/wireless-communications-onramp/wireless 

For your PDF lab report, you must:
- Include all plots and answer all questions as directed in Parts 2 and 3 of the lab guidance.
- Upload the PDF to Gradescope.