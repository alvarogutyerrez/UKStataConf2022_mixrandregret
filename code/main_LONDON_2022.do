clear all
set more off
capture log close 
set seed 42

cd "C:\"
*Install mixrandregret
cap ado uninstall mixrandregret
net install mixrandregret, from("https://raw.githubusercontent.com/ziyue16/mixrandregret/master/src/")

global stlog = "C:\Users\u0133260\Documents\_local_git_repos\UK_StataConf_2022\beamer_London2022\stlog"
globa graphs_route = "C:\Users\u0133260\Documents\_local_git_repos\UK_StataConf_2022\beamer_London2022\figures"

*cd "$route_data_code"
sjlog using "${stlog}\list_original_data" , replace 
scalar server = "https://data.4tu.nl/ndownloader/"
scalar doi = "files/24015353"
import delimited   "`=server + doi'" ,clear
keep obs id   tt1 tc1 tt2 tc2 tt3 tc3 choice 
list obs id   tt1 tc1 tt2 tc2 tt3 tc3 choice in 1/3,sepby(obs)
sjlog close , replace


sjlog using    "${stlog}\manipu_long" , replace 
rename (choice)  (choice_w)
qui reshape long tt tc  , i(obs) j(altern)
generate choice = 0
replace  choice = 1 if  choice_w==altern  
label define  alt_label 1 "First" 2 "Second" 3 "Third" 
label values  altern alt_label
list obs altern choice id  tt tc   in 1/6, sepby(obs)
sjlog close , replace


sjlog using   "${stlog}\RRM_classic_cluster" , replace 
randregret choice  tc tt, gr(obs) alt(altern) rrmfn(classic) ///
nocons cluster(id)  nolog
matrix b_rrm = e(b)
sjlog close , replace


matrix zero = J(1,1,0.01)
matrix init_mix_rrm = b_rrm  ,zero
matrix li init_mix_rrm 


sjlog using   "${stlog}\mixRRM_normal" , replace 
mixrandregret choice  tc , gr(obs) alt(altern) rand(tt) id(id) ///
nocons cluster(id)  nrep(2500) from(init_mix_rrm) tech(bhhh)  nolog
matrix b_mixrrm = e(b)
sjlog close , replace



sjlog using "${stlog}\mixRRM_normal_idl" , replace 
preserve 
/* Computing Individual Level Parameters */
qui mixrbeta tt , nrep(2500)  replace saving("${graphs_route}\mixRRM_normal_idl") 
use "${graphs_route}\mixRRM_normal_idl" , replace
list id  tt  in 1/5 
sjlog close , replace
/* Kdensity of the estimates. */
graph twoway histogram tt || kdensity tt,  ///
	title("Conditional Distribution for Coefficient of Total Time") ///
	scheme(white_tableau )  n(100)  
qui graph export "${graphs_route}\mixRRM_normal_idl.pdf", replace 
restore


sjlog using   "${stlog}\mixRRM_ln" , replace 
gen ntt = -1 * tt
mixrandregret choice  tc , gr(obs) alt(altern) rand(ntt ) ln(1) id(id) ///
nocons cluster(id)  nrep(2500) tech(bhhh) from(b_mixrrm) nolog
sjlog close , replace

preserve
sjlog using  "${stlog}\mixRRM_ln_idl" , replace 
/* Computing Individual Level Parameters */
qui mixrbeta ntt , nrep(2500)  replace saving("${graphs_route}\mixRRM_ln_idl") 
use "${graphs_route}\mixRRM_ln_idl" , replace
replace ntt = -1 * ntt /*reverse sign for graph*/
list id  ntt  in 1/5 
sjlog close , replace
/* Kdensity of the estimates. */
graph twoway histogram ntt || kdensity ntt,  ///
	title("Conditional Distribution for Coefficient of Total Time") ///
	scheme(white_tableau )  n(100)  
qui graph export "${graphs_route}\mixRRM_ln_idl.pdf", replace 
restore


sjlog using   "${stlog}\mixRRM_delta" , replace 
nlcom (mean_time: -1*exp([Mean]_b[ntt ]+0.5*[SD]_b[ntt ]^2)) ///
(med_time: -1*exp([Mean]_b[ntt ])) /// 
(sd_time: exp([Mean]_b[ntt ]+0.5*[SD]_b[ntt ]^2) * sqrt(exp([SD]_b[ntt ]^2)-1))
sjlog close , replace













