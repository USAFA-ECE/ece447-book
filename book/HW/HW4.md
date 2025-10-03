# Homework 4

Chapter 5

## Due NLT 9 Oct (Lesson 23) by 2359 on Gradescope

## Directions: 
- Collaboration is authorized as noted in the syllabus Collaboration policy. 
- All homework must be complete, error-free, and _neatly organized_. **Points may be deducted for sloppy and illegible work.** 
- Answers should be clearly indicated by a box.
- Use engineering notation with proper units.
- Submit work to Gradescope with pages assigned to each problem. Scans/uploads must be legible and neat without excessive margins.

## Problems:
- Starting from $m(t)$ and and $\hat{m}(t)$ as defined at the beginning of Section 5.2.2, retrace the steps provided in the textbook to show mathematically why adding a bit to a uniform analog-to-digital converter results in a 6dB increase in the output SNR. You can simply follow the same equations used in Section 5.2.2 and 5.2.4, but you **must provide a clear, concise explanation for each step**. For example, you could start with something like the following:
    
    -------------------------

    Let $m(t)=\sum_k m(kT_s)\cdot\text{sinc}(2\pi Bt-k\pi)$, where $m(kT_s)$ is the $k$ th sample of $m(t)$.
    
    Let the signal reconstructed from quantized samples be $\hat{m}(t)=\sum_k \hat{m}(kT_s)\cdot\text{sinc}(2\pi Bt-k\pi)$, where $\hat{m}(kT_s)$ is the $k$ th *quantized* sample of $m(t)$.

    The error between $m(t)$ and $\hat{m}(t)$ is given by

    $q(t)=\hat{m}(t)-m(t)=...$

    ---------------------

    While clearly you will be copying *some* parts of the text, try to put your explanations in your own words as much as possible. The intent of this problem is to ensure you understand the mathematical relationship between SNR and the number of quantization bits.

- 5.2-2 --> In Part (b) when it asks for the "number of binary pulses required" it simply means the number of bits.
- 5.2-3 --> Reference Example 5.2 for a similar problem (not exactly the same, but similar!)
- 5.2-11 --> Replace "The PCM encoder of Prob 5.2-10 is used to convert these signals before they are time-multiplexed into a single data stream" with "The PCM encoder uses L=512 levels to convert these signals to bits before they are time-multiplexed into a single data stream." You do not need to work through or look at Prob 5.2-10 to solve this.
