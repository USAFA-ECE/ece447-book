# Homework 6

Chapter 6 (6.7-6.9)

## Due NLT 4 Nov (Lesson 31) by 2359 on Gradescope

## Directions: 
- Collaboration is authorized as noted in the syllabus Collaboration policy. 
- All homework must be complete, error-free, and _neatly organized_. **Points may be deducted for sloppy and illegible work.** 
- Answers should be clearly indicated by a box.
- Use engineering notation with proper units.
- Submit work to Gradescope with pages assigned to each problem. Scans/uploads must be legible and neat without excessive margins.

## Problems:
- **6.7-2**
- **6.7-4** --> You can figure out Part (a). In Part (b), you want to compare the transmitted power for the binary case to that of the 16-ary case. Transmitted power is equal to the average energy per bit multiplied by the pulse rate. For the binary case, let the average bit energy be $E_b$ and the pulse rate be $R_b$ - since in the binary case the bit rate equals the pulse rate. Then $P_{binary}=E_bR_b$. 

    It can be shown (in Problem 6.7-3 if you are interested!) that the average energy per bit for $M$-ary PAM is given by

    $$E_{av}=\frac{M^2-1}{3}E_b,$$
    
    where we assume all $M$ levels are equally likely. Then the transmitted power is $E_{av}$ multiplied by the pulse rate.
- **6.7-5** --> Don't confuse the number of bits per sample with the $\log_2(M)$ number of bits per pulse! Steps to follow:

    1. Find the number of bits/sample and bit rate (bits/sec), $R_b$.
    2. Use the available bandwidth and roll-off factor to find the pulse rate (pulses/sec), $R_s$. This can also be called the symbol rate - hence the subscript $s$.
    3. Calculate the number of bits per pulse.

- **6.8-1** --> Part (a): remember binary PSK is equivalent to polar signaling. Part (b): use Carson's Rule, where $\Delta f$ is the peak frequency deviation from the center point between the two frequencies and $B$ is the bandwidth of the baseband signal.
- **6.8-1 Add-on Part (c)** --> If the modulator generates a 16-PSK signal, what is the bandwidth of the modulated output? What about for a 16-QAM signal? 