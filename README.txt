-> Names and UFID of group members:
	1. Naman Arora - UFID: 39790439
	2. Drona Banerjee - UFID: 46627749

-> Steps to run the code:

	Step 1 - Change directory to the mix project (Proj1)
	Step 2 - Execute the code using mix run proj1.exs start_number end_number

-> There are four types of worker actors in the logic:
	1. The main GenServer, supervised directly by the supervisor (M).
	2. A Task for each number in the provided range that checks the vampire qualities of the number assigned to it by M (ti).
	3. A Task for each divisor for each ti givin that divisor lies within the range of 10^(num_of_digits/2-1)..(10^(num_of_digits/2)-1) (t2ij)
	4. An agent to accumulate all the numbers and their respective divisors, which have been tested positive for vampire qualities. (A)
		-> M + t(i=[n2-n1]) + t(i=[n2-n1])(j=num_of_divisors_within_R) + A
			where n1,n2 are the starting and ending ranges
			R= 10^(num_of_digits/2-1)..(10^(num_of_digits/2)-1)

-> This particular stratergy was selected on trial and error basis.

-> Size of work unit -> ('k' corresponds to a single vampire quality check, a finite number of 'l' make a 'k')
		1. M: The whole range of numbers, ie (n2-n1)*k
		2. ti: Checking the vampire quality of ith number, ie k
		3. tij: Checking the vampire quality of ith number against jth given divisor, ie l

-> Result of running program for: mix run proj1.exs 100000 200000

102510 201 510
163944 396 414
140350 350 401
105210 210 501
104260 260 401
129640 140 926
120600 201 600
153436 356 431
180225 225 801
115672 152 761
131242 311 422
126027 201 627
152685 261 585
145314 351 414
193257 327 591
136948 146 938
172822 221 782
133245 315 423
190260 210 906
182250 225 810
105750 150 705
134725 317 425
174370 371 470
182650 281 650
125248 152 824
108135 135 801
116725 161 725
156915 165 951
126846 261 486
146137 317 461
123354 231 534
186624 216 864
175329 231 759
173250 231 750
105264 204 516
162976 176 926
192150 210 915
125500 251 500
125433 231 543
197725 275 719
193945 395 491
146952 156 942
156289 269 581
135828 231 588
136525 215 635
152608 251 608
118440 141 840
129775 179 725
156240 240 651
135837 351 387
110758 158 701
125460 204 615 246 510
117067 167 701
132430 323 410
124483 281 443
150300 300 501
180297 201 897


Running time for mix run proj1.exs 100000 200000

real 0.93s
user 8.75s
sys 0.20s

-> CPU time/real time = (user + sys)/real = 9.62

-> Largest problem solved mix run proj1.exs 1 10000000
-> Larget vampire number found: 939658
