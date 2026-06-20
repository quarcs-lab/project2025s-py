replace State = "Andhra Pradesh" if State == "02"
replace State = "Assam" if State == "03"
replace State = "Bihar" if State == "04"
replace State = "Gujarat" if State == "05"
replace State = "Haryana" if State == "06"
replace State = "Himachal Pradesh" if State == "07"
replace State = "Jammu & Kashmir" if State == "08"
replace State = "Karnataka" if State == "09"
replace State = "Kerala" if State == "10"
replace State = "Madhya Pradesh" if State == "11"
replace State = "Maharashtra" if State == "12"
replace State = "Manipur" if State == "13"
replace State = "Meghalaya" if State == "14"
replace State = "Nagaland" if State == "15"
replace State = "Orissa" if State == "16"
replace State = "Punjab" if State == "17"
replace State = "Rajasthan" if State == "18"
replace State = "Sikkim" if State == "19"
replace State = "Tamil Nadu" if State == "20"
replace State = "Tripura" if State == "21"
replace State = "Uttar Pradesh" if State == "22"
replace State = "West Bengal" if State == "23"
replace State = "A & N Islands" if State == "24"
replace State = "Arunachal Pradesh" if State == "25"
replace State = "Chandigarh" if State == "26"
replace State = "Dadra & Nagar Haveli" if State == "27"
replace State = "Delhi" if State == "28"
replace State = "Goa" if State == "29"
replace State = "Lakshdweep" if State == "30"
replace State = "Mizoram" if State == "31"
replace State = "Pondicherry" if State == "32"
replace State = "Daman & Diu" if State == "33"

**PCA**
factor B7_q3 B7_q4 B7_q5 B7_q6 B7_q7 B7_q8 B7_q9 B7_q10 B7_q11 B7_q12 B7_q13 B7_q14 B7_q15 B7_q16 B7_q17 B7_q18 B7_q19 B7_q20, pcf
screeplot, yline(1)
rotate

predict LC_Performance LC_Telecast SC CH_relig LC_shows Sports
collapse (mean) LC_Performance LC_Telecast SC CH_relig LC_shows Sports, by(State)