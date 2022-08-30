
clear all
set more off
capture log close 

cd "C:\"
*Install mixrandregret
*cap ado uninstall mixrandregret
*net install mixrandregret, from("https://raw.githubusercontent.com/ziyue16/mixrandregret/master/src/")


global stlog = "C:\Users\u0133260\Documents\_local_git_repos\UK_StataConf_2022\beamer_London2022\stlog"


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
nocons cluster(id)  
matrix mu = e(b)
sjlog close , replace

cap mata: mata drop RRM_log() 
cap mata: mata drop pbb_pred() 
cap mata: mata drop  mixRRM_gf0()

matrix zero = J(1,1,0.01)
matrix init = mu,zero
matrix li init 


sjlog using   "${stlog}\mixRRM_cluster" , replace 
mixrandregret choice  tc , gr(obs) alt(altern) rand(tt) id(id) ///
nocons cluster(id)  nrep(1000) from(init) tech(bfgs)
sjlog close , replace

matrix zero = J(1,1,2)
matrix init = mu,zero
matrix li init 


sjlog using   "${stlog}\mixRRM_ln" , replace 
mixrandregret choice  tc , gr(obs) alt(altern) rand(tt) ln(1) id(id) ///
nocons cluster(id)  nrep(1000) tech(bfgs) from(init)
sjlog close , replace
