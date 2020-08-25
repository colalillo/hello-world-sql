--1. Import questionnaire data

		--1a. Drop current table
			drop table Questionnaire_AWKCVA_prelim
			drop table Questionnaire_AWKCVA


		--1b. Import new data. Check data for errors. 
			
			select * from Questionnaire_AWKCVA_prelim

			select count(*) from Questionnaire_AWKCVA_prelim


		--1c. Add CaseId and JitBit Ticket # to the questionnaire table and create the new base table, Questionnaire_AWKCVA
		

				declare @AWKCVA_Ticket varchar (8)
			------DON'T FORGET TO SET TICKET #--------------------------------------------------------------------
				set @AWKCVA_Ticket = '24218067'
			------DON'T FORGET TO SET TICKET #--------------------------------------------------------------------
				select *, @AWKCVA_Ticket as 'Ticket#'
				into Questionnaire_AWKCVA
				from Questionnaire_AWKCVA_prelim

						
						select * from Questionnaire_AWKCVA
						
						select count(*) from Questionnaire_AWKCVA



--2. Analyze Claimant Data and check for major discrepancies


			--2a. Find any claimants who currently have questionnaire rec'd marked as true in SLAM

							drop table #Discrepancy4_AWKCVA
							drop table #DiscrepQuest_AWKCVA


					select	Q.[S3 Id] as 'ClientId', C.QuestionnaireReceived, 
							case
								when C.QuestionnaireReceived = 1 then 'Claimant already has questionnaire received marked as true in SLAM' 
								when C.QuestionnaireReceived <> 1 or C.QuestionnaireReceived is null then 'No Issue'
								Else 'Look Into'
								End as 'Issue Detail: Quest Recd already true in SLAM'
					into	#DiscrepQuest_AWKCVA
					from	Clients as C
								INNER JOIN Questionnaire_AWKCVA as Q on C.Id = Q.[S3 Id]
					where	Q.[S3 Id] is not NULL
					

			--2a.5 Create only the discrepancies for questionnaires table:
					drop table #Discrepancy4_AWKCVA

					select *
					into #Discrepancy4_AWKCVA
					from #DiscrepQuest_AWKCVA
					where [Issue Detail: Quest Recd already true in SLAM] <> 'No Issue'
					
					select * from #Discrepancy4_AWKCVA


			--2b. Leave note CSV for client level discrepancy in 2a

					select	distinct Q.[S3 Id] as 'Id', concat('Questionnaire processing issue: Claimant already has questionnaire received marked as true in SLAM. Per AK, will not process second questionnaire. Ticket #: ', Ticket#) as 'NewClientNote'
					from	Clients as C
								INNER JOIN Questionnaire_AWKCVA as Q on C.Id = Q.[S3 Id]
					where	C.QuestionnaireReceived = 1


		
			--2a. Create table combining SLAM and questionnaire data

						drop table #ClientCheck1_AWKCVA


					Select	Q.[S3 ID] as 'Q Client Id', C.Id as 'SLAM Client Id', Q.[Claimant First Name], Q.[Claimant Last Name] as Quest_LastName, Q.[Attorney ID], C.AttorneyReferenceId, --Q.[Cl SSN] as Quest_SSN, 
							C.LastName as SLAM_LastName, C.FirstName as SLAM_FirstName, C.SSN as SLAM_SSN, C.ThirdPartyId,
							Case
								When C.ThirdPartyId is null and C.FirstName is null and C.LastName is null then 'Issue - Claimant not in SLAM'
								Else 'Claimant is in SLAM'
								End As 'Claimant in SLAM?',
							Case	
								When Q.[Attorney ID] = C.AttorneyReferenceId then 'Good - Third Party Id Match'
								When Q.[Attorney ID] <> C.AttorneyReferenceId then 'Issue - Third Party Id Mismatch, No SSN'
								Else 'Issue - Look Into'
								End As 'SSN or ThirdPartyId Match?',
							Case
								When Q.[Claimant Last Name] = C.LastName then 'Match'
								When Q.[Claimant Last Name] = C.FirstName and Q.[Claimant First Name] = C.LastName then 'Check, names switched, but ok'
								When SOUNDEX(Q.[Claimant Last Name]) = soundex(c.lastname) then 'Check, but probably ok'
								Else 'Issue - Lastname mismatch'
								End As 'Last Name Match?'
					Into	#ClientCheck1_AWKCVA
					From	Questionnaire_AWKCVA as Q  
								LEFT JOIN Clients as C on Q.[S3 ID] = C.Id


								select * from #ClientCheck1_AWKCVA

								select * from #ClientCheck1_AWKCVA where [SSN or ThirdPartyId Match?] like 'Issue%' or [Last Name Match?] like 'Check%' or [Last Name Match?] like 'Issue%' or [Claimant in SLAM?] like 'Issue%'

								select count(*) from #ClientCheck1_AWKCVA
								


						--Review Last Name "Checks" and Mismatches!!
								select * from #ClientCheck1_AWKCVA where [Last Name Match?] like 'Check%'
								

									select * from Questionnaire_AWKCVA where [S3 ID] = 226938

									update Questionnaire_AWKCVA 
									set [Claimant Last Name] = 'Castillo'
									where [S3 ID] = 355592
							


			--2b. Identify Claimants who have a SSN or last name mismatch or is not in SLAM

							drop table #Discrepancy1_AWKCVA


					Select	*, 
							case
								when [SSN or ThirdPartyId Match?] like 'Issue%' or [Last Name Match?] like 'Issue%' or [Claimant in SLAM?] like 'Issue%' then 'Issue - Data on spreadsheet does not match claimant data in SLAM' 
								when [SSN or ThirdPartyId Match?] like 'Issue%' or [Last Name Match?] like 'Issue%' or [Claimant in SLAM?] like 'Issue%' then 'Issue - Data on spreadsheet does not match claimant data in SLAM'
								when [SSN or ThirdPartyId Match?] like 'Good%' or [Last Name Match?] = 'Match' and [Claimant in SLAM?] = 'Claimant is in SLAM' then 'No Issue' 
								when [Last Name Match?] like 'Check%' then 'No Issue'
								else 'Look Into'
								End as 'Issue Detail: Claimant data does not match SLAM'
					Into	#Discrepancy1_AWKCVA
					From	#ClientCheck1_AWKCVA
				


					select * from  #Discrepancy1_AWKCVA where [Issue Detail: Claimant data does not match SLAM] <> 'No Issue'


			--2b1. Leave note CSV for client level discrepancy in 2b
					
				Select	distinct [SLAM Client Id] as Id, 
						Case
							When [Issue Detail: Claimant data does not match SLAM] like 'Issue%' then concat('Questionnaire processing issue: Data on spreadsheet does not match claimant data in SLAM. Ticket #: ', Q.Ticket#) 
							Else 'Look Into'
							End As 'NewClientNote'
				From	#Discrepancy1_AWKCVA as C
								Left Join Questionnaire_AWKCVA as Q on C.[SLAM Client Id] = Q.[S3 ID]
								Left Join #Discrepancy4_AWKCVA D4 on D4.[ClientId] = C.[SLAM Client Id]
				Where	C.[Issue Detail: Claimant data does not match SLAM] <> 'No Issue'
						and D4.[ClientId] is NULL




			--2c. Create temp table to check that each Client Id shows up only once
			
							drop table #ClientCheck2_AWKCVA


					Select	sub.*,
							Case
								When sub.[Count of Client Id] = 1 then 'Good'
								Else 'Issue'
								End As 'Client Id Count Good?'
					Into #ClientCheck2_AWKCVA
					From 
							(
							Select	[S3 ID], Count([S3 ID]) as 'Count of Client Id'
							From	Questionnaire_AWKCVA 
							Group by [S3 ID]
							) as sub



							select * from #ClientCheck2_AWKCVA where [Client Id Count Good?] <> 'Good'

							--Delete a duplicate?
							DELETE FROM Questionnaire_AWKCVA WHERE [S3 Id] = 225550 And [Marital Status] = 'Married'


			--2d. Identify claimants whose ClientId appears more than once

							drop table #Discrepancy2_AWKCVA


					Select	*, 
							case 
								when [Client Id Count Good?] <> 'Good'  then 'Claimant is on spreadsheet more than once'
								when [Client Id Count Good?] = 'Good'  then 'No Issue'
								Else 'Look Into'
								End As 'Issue Detail: Duplicate Records'
					Into	#Discrepancy2_AWKCVA
					From	#ClientCheck2_AWKCVA
				
			

						select * from #Discrepancy2_AWKCVA where [Issue Detail: Duplicate Records] <> 'No Issue'


			--2e. Leave note CSV for client level discrepancy in 2d
								
					Select	C.[S3 ID] as Id, concat('Questionnaire processing issue: Claimant is on spreadsheet more than once with differing data. Ticket #: ', Q.[Ticket#]) as 'NewClientNote'
					From	#ClientCheck2_AWKCVA as C
							Left Join Questionnaire_AWKCVA as Q on C.[S3 ID] = Q.[S3 Id]
							Left Join #Discrepancy4_AWKCVA as D4 on D4.[ClientId] = C.[S3 Id]
					Where	[Client Id Count Good?] = 'Issue'
							AND D4.[ClientId] is NULL
					Group By C.[S3 ID], concat('Questionnaire processing issue: Claimant is on spreadsheet more than once with differing data. Ticket #: ', Q.[Ticket#])




			--2f. Find claimants with Misc. Discrepancies from instructions 
					

								drop table #Discrepancy3_AWKCVA


					Select	[S3 ID], [Claimant Last Name], [Claimant First Name], [Scribbles?], 
							Case
								When [Scribbles?] is not null  then 'Issue - Has scribbles'
								When [Scribbles?] is null then 'No Issue'
								Else 'Look Into'
								End As 'Issue Detail: Scribbles?'
					Into	#Discrepancy3_AWKCVA
					From	Questionnaire_AWKCVA


						select	* 
						from	#Discrepancy3_AWKCVA 
						where	[Issue Detail: Scribbles?] not like 'No Issue'
								



			--2g. Leave note CSV for client level discrepancy in 2f
			
				Select	C.[S3 ID] as Id, 
						concat('Questionnaire processing issue: According to instructions was not able to process questionnaire data for claimant (scribbles). Ticket #: ', Q.[Ticket#]) As 'NewClientNote'
				From	#Discrepancy3_AWKCVA as C
							Left Join Questionnaire_AWKCVA as Q on C.[S3 ID] = Q.[S3 Id]
							Left Join #Discrepancy4_AWKCVA as D4 on C.[S3 Id] = D4.[ClientId]
				Where	[Issue Detail: Scribbles?] not like 'No Issue'




			--2j. Compile a discrepancy report


						drop table #AllTheDiscrepancies_AWKCVA


					select	distinct Q.[Case] as Casename, Q.[S3 ID] as 'Client Id', Q.[Claimant Last Name], Q.[Claimant First Name], --Q.[Which Questionnaire?],
							D1.[Attorney ID], D1.AttorneyReferenceId,
							D1.[Issue Detail: Claimant data does not match SLAM],
							D1.[Claimant in SLAM?], D1.[SSN or ThirdPartyId Match?], D1.[Last Name Match?],
							D2.[Issue Detail: Duplicate Records], 
							D3.[Scribbles?], 
							D3.[Issue Detail: Scribbles?], 
							D4.[Issue Detail: Quest Recd already true in SLAM]
					into	#AllTheDiscrepancies_AWKCVA
					from	Questionnaire_AWKCVA as Q
								LEFT OUTER JOIN #Discrepancy1_AWKCVA as D1 on D1.[Q Client Id] = Q.[S3 ID]
								LEFT OUTER JOIN #Discrepancy2_AWKCVA as D2 on D2.[S3 ID] = Q.[S3 ID]
								LEFT OUTER JOIN #Discrepancy3_AWKCVA as D3 on D3.[S3 ID] = Q.[S3 ID]
								LEFT OUTER JOIN #Discrepancy4_AWKCVA as D4 on D4.[ClientId] = Q.[S3 ID]
					where	D1.[Issue Detail: Claimant data does not match SLAM] <> 'No Issue' or 
							D2.[Issue Detail: Duplicate Records] <> 'No Issue' or 
							D3.[Issue Detail: Scribbles?] <> 'No Issue' or 
							D4.[Issue Detail: Quest Recd already true in SLAM] <> 'No Issue'


							select * from #AllTheDiscrepancies_AWKCVA

							select count(*) from #AllTheDiscrepancies_AWKCVA
							

							--2j1: Discrepancy report for CM to review
						
						select	*
						from	#AllTheDiscrepancies_AWKCVA 
						where	[Issue Detail: Quest Recd already true in SLAM] = 'no issue'



						--2j1: Discrepancy report to notify CM that the claimant already had questionnaire rec'd as true
						
						select	*
						from	#AllTheDiscrepancies_AWKCVA 
						where	[Issue Detail: Quest Recd already true in SLAM] <> 'no issue'





							--Clear out discrepancy table when processing questionnaire discrepancy report

								delete from #AllTheDiscrepancies_AWKCVA where [Issue Detail: Quest Recd already true in SLAM] = 'No Issue' and [Issue Detail: Scribbles?] = 'Issue - Has scribbles'


								select * from #AllTheDiscrepancies_AWKCVA



			--total base analysis pt 1
					
					drop table #MilitaryAnalysis_AWKCVA


					select	D.[Client Id], Q.[Case] as Casename, Q.[S3 ID], Q.[Claimant Last Name], Q.[Claimant First Name], Q.[Eligible Tricare, VA or IHS?], Q.[Inco Name 1], Q.[Inco Address 1], Q.[Inco Phn # 1], Q.[Inco Gr # 1], Q.[Inco ID # 1], Q.[Inco Name 2], Q.[Inco Address 2], Q.[Inco Phone 2], Q.[Inco Gr # 2], Q.[Inco ID # 2], Q.[Inco Name 3], Q.[Inco Address 3], Q.[Inco Phone 3], Q.[Inco Gr # 3], Q.[Inco ID # 3], Q.[Auth# To Resolve Prvt Liens?],
							Case
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 1] like 'VA' or [Inco Name 1] like 'VA %' or [Inco Name 1] like 'V.A.%' or [Inco Name 1] like '%Veterans Affairs%' or [Inco Name 1] like '%Army%' or [Inco Name 1] like '%Tricare%'or [Inco Name 1] like '%Navy%' or [Inco Name 1] like '%Air Force%' or [Inco Name 1] like '%Airforce%' or [Inco Name 1] like '%USFHP%' or [Inco Name 1] like '%US Family Health Plan%' or [Inco Name 1] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 1] like '%ChampVA%' or [Inco Name 1] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 1] like '%tribe' or [Inco Name 1] like '%Indian%' or [Inco Name 1] like '%IHS%' then '1459'
					
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'M2'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 1] like 'VA' or [Inco Name 1] like 'VA %' or [Inco Name 1] like 'V.A.%' or [Inco Name 1] like '%Veterans Affairs%' or [Inco Name 1] like '%Army%' or [Inco Name 1] like '%Tricare%'or [Inco Name 1] like '%Navy%' or [Inco Name 1] like '%Air Force%' or [Inco Name 1] like '%Airforce%' or [Inco Name 1] like '%USFHP%' or [Inco Name 1] like '%US Family Health Plan%' or [Inco Name 1] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 1] like '%ChampVA%' or [Inco Name 1] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 1] like '%tribe' or [Inco Name 1] like '%Indian%'  or [Inco Name 1] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'M4'
								
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 1] like 'VA' or [Inco Name 1] like 'VA %' or [Inco Name 1] like 'V.A.%' or [Inco Name 1] like '%Veterans Affairs%' or [Inco Name 1] like '%Army%' or [Inco Name 1] like '%Tricare%'or [Inco Name 1] like '%Navy%' or [Inco Name 1] like '%Air Force%' or [Inco Name 1] like '%Airforce%' or [Inco Name 1] like '%USFHP%' or [Inco Name 1] like '%US Family Health Plan%' or [Inco Name 1] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 1] like '%ChampVA%' or [Inco Name 1] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 1] like '%tribe' or [Inco Name 1] like '%Indian%' or [Inco Name 1] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'M6'
							Else 'Probably Private'
							End as 'M_Pull_1',

							Case
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 2] like 'VA' or [Inco Name 2] like 'VA %' or [Inco Name 2] like 'V.A.%' or [Inco Name 2] like '%Veterans Affairs%' or [Inco Name 2] like '%Army%' or [Inco Name 2] like '%Tricare%'or [Inco Name 2] like '%Navy%' or [Inco Name 2] like '%Air Force%' or [Inco Name 2] like '%Airforce%' or [Inco Name 2] like '%USFHP%' or [Inco Name 2] like '%US Family Health Plan%' or [Inco Name 2] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 2] like '%ChampVA%' or [Inco Name 2] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 2] like '%tribe' or [Inco Name 2] like '%Indian%' or [Inco Name 2] like '%IHS%' then '1459'
					
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'M2'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 2] like 'VA' or [Inco Name 2] like 'VA %' or [Inco Name 2] like 'V.A.%' or [Inco Name 2] like '%Veterans Affairs%' or [Inco Name 2] like '%Army%' or [Inco Name 2] like '%Tricare%'or [Inco Name 2] like '%Navy%' or [Inco Name 2] like '%Air Force%' or [Inco Name 2] like '%Airforce%' or [Inco Name 2] like '%USFHP%' or [Inco Name 2] like '%US Family Health Plan%' or [Inco Name 2] like '%U.S. Family Health Plan%' then'1599'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 2] like '%ChampVA%' or [Inco Name 2] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 2] like '%tribe' or [Inco Name 2] like '%Indian%' or [Inco Name 2] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'M4'
								
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 2] like 'VA' or [Inco Name 2] like 'VA %' or [Inco Name 2] like 'V.A.%' or [Inco Name 2] like '%Veterans Affairs%' or [Inco Name 2] like '%Army%' or [Inco Name 2] like '%Tricare%'or [Inco Name 2] like '%Navy%' or [Inco Name 2] like '%Air Force%' or [Inco Name 2] like '%Airforce%' or [Inco Name 2] like '%USFHP%' or [Inco Name 2] like '%US Family Health Plan%' or [Inco Name 2] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 2] like '%ChampVA%' or [Inco Name 2] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 2] like '%tribe' or [Inco Name 2] like '%Indian%' or [Inco Name 2] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'M6'
							Else 'Probably Private'
							End as 'M_Pull_2',

							Case
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 3] like 'VA' or [Inco Name 3] like 'VA %' or [Inco Name 3] like 'V.A.%' or [Inco Name 3] like '%Veterans Affairs%' or [Inco Name 3] like '%Army%' or [Inco Name 3] like '%Tricare%'or [Inco Name 3] like '%Navy%' or [Inco Name 3] like '%Air Force%' or [Inco Name 3] like '%Airforce%' or [Inco Name 3] like '%USFHP%' or [Inco Name 3] like '%US Family Health Plan%' or [Inco Name 3] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 3] like '%ChampVA%' or [Inco Name 3] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 3] like '%tribe' or [Inco Name 3] like '%Indian%' or [Inco Name 3] like '%IHS%' then '1459'
					
								When [Eligible Tricare, VA or IHS?] = 'Truthy' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'M2'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 3] like 'VA' or [Inco Name 3] like 'VA %' or [Inco Name 3] like 'V.A.%' or [Inco Name 3] like '%Veterans Affairs%' or [Inco Name 3] like '%Army%' or [Inco Name 3] like '%Tricare%'or [Inco Name 3] like '%Navy%' or [Inco Name 3] like '%Air Force%' or [Inco Name 3] like '%Airforce%' or [Inco Name 3] like '%USFHP%' or [Inco Name 3] like '%US Family Health Plan%' or [Inco Name 3] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 3] like '%ChampVA%' or [Inco Name 3] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 3] like '%tribe' or [Inco Name 3] like '%Indian%' or [Inco Name 3] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Falsey' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'M4'
								
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 3] like 'VA' or [Inco Name 3] like 'VA %' or [Inco Name 3] like 'V.A.%' or [Inco Name 3] like '%Veterans Affairs%' or [Inco Name 3] like '%Army%' or [Inco Name 3] like '%Tricare%'or [Inco Name 3] like '%Navy%' or [Inco Name 3] like '%Air Force%' or [Inco Name 3] like '%Airforce%' or [Inco Name 3] like '%USFHP%' or [Inco Name 3] like '%US Family Health Plan%' or [Inco Name 3] like '%U.S. Family Health Plan%' then '1599'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 3] like '%ChampVA%' or [Inco Name 3] like '%Champ VA%' then '1617'
								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 3] like '%tribe' or [Inco Name 3] like '%Indian%' or [Inco Name 3] like '%IHS%' then '1459'

								When [Eligible Tricare, VA or IHS?] = 'Blanky' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'M6'
							Else 'Probably Private'
							End as 'M_Pull_3',
							Ticket#
					Into	#MilitaryAnalysis_AWKCVA
					from	Questionnaire_AWKCVA as Q
								Left Join #AllTheDiscrepancies_AWKCVA as D on D.[Client Id] = Q.[S3 ID]



						select * from  #MilitaryAnalysis_AWKCVA

						select * from  #MilitaryAnalysis_AWKCVA where [Eligible Tricare, VA, HIS?] is null

						select distinct [Eligible Tricare, VA, HIS?] from  #MilitaryAnalysis_AWKCVA 

						select distinct [Military Analysis] from  #MilitaryAnalysis_AWKCVA 


			--3b. QA Summary

					--Summary: All
					select	M.CaseName, [S3 ID], [M_Pull_1],  [M_Pull_2], [M_Pull_3],
							D.[Issue Detail: Claimant data does not match SLAM],
							D.[Issue Detail: Duplicate Records],
							D.[Issue Detail: Scribbles?],
							D.[Issue Detail: Quest Recd already true in SLAM]
					from	#MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=M.[S3 ID]
						
						
					--Summary: Liens that need to be created
						--# of Military liens to create
						select	M.CaseName, [S3 ID], [M_Pull_1],  [M_Pull_2], [M_Pull_3],
								D.[Issue Detail: Claimant data does not match SLAM],
								D.[Issue Detail: Duplicate Records],
								D.[Issue Detail: Scribbles?],
								D.[Issue Detail: Quest Recd already true in SLAM]
						from #MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=M.[S3 ID]
						Where (M.[M_Pull_1] = '1459' or M.[M_Pull_1] = '1599' or M.[M_Pull_1] = '1617' or
								M.[M_Pull_2] = '1459' or M.[M_Pull_2] = '1599' or M.[M_Pull_2] = '1617' or
								M.[M_Pull_3] = '1459' or M.[M_Pull_3] = '1599' or M.[M_Pull_3] = '1617')
								and D.[Client Id] is null
						


			--3c. Find claimants who already have a Military or IHS lien in SLAM. Send these to Nicole/Lorraine. 

					Select	F.ClientId, F.Id as 'SLAM Lien Id', F.LienType, F.Stage, M.*
					From	#MilitaryAnalysis_AWKCVA as M 
								LEFT OUTER JOIN FullProductViews as F on M.[S3 ID]=F.ClientId
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on M.[S3 ID]=D.[Client Id]
					Where	(F.Lientype like 'Military%' or F.LienType like 'ihs%')
							and D.[Client Id] is null
							and (M.[M_Pull_1] = '1459' or M.[M_Pull_1] = '1599' or M.[M_Pull_1] = '1617' or
								M.[M_Pull_2] = '1459' or M.[M_Pull_2] = '1599' or M.[M_Pull_2] = '1617' or
								M.[M_Pull_3] = '1459' or M.[M_Pull_3] = '1599' or M.[M_Pull_3] = '1617')

							

							

			--3d. Create liens CSV for M1, M3, and M5 (part 1)
			drop table #M1_Create

					select	[S3 ID] as ClientId, 
						Case
							When [M_Pull_1] like '1459' then 'IHS Lien'
							Else 'Military Lien - MT'
						End as 'Lientype',
						Case
							When [M_Pull_1] like '1599' then [M_Pull_1]
							When [M_Pull_1] like '1617' then [M_Pull_1]
							When [M_Pull_1] like '1459' then [M_Pull_1]
						End as 'LienholderId',
						Case
							When [M_Pull_1] like '1599' then '1214'
							When [M_Pull_1] like '1617' then '1239'
							When [M_Pull_1] like '1459' then '1214'
						End as 'CollectorId', 
							Case
								When M.Casename like '%GRG%' then 141 
								Else '338'
								End as 'AssignedUserId', 
							'To Send - EV' as 'Stage', '1' as 'StatusId', 'Yes' as 'OnBenefits', cast(getdate() as date) as 'OnBenefitsVerified', 
							[Inco Name 1], [Inco Name 2], [Inco Name 3], [M_Pull_1], [M_Pull_2], [M_Pull_3], 'Group 1' as 'Group',
							[Inco Address 1], [Inco Phn # 1], [Inco Gr # 1], [Inco ID # 1], [Inco Address 2], [Inco Phone 2], [Inco Gr # 2], [Inco ID # 2], [Inco Address 3], [Inco Phone 3], [Inco Gr # 3], [Inco ID # 3], [Ticket#]
					Into	#M1_Create
					From	#MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on M.[S3 ID]=D.[Client Id]
					Where	(M.[M_Pull_1] = '1459' or M.[M_Pull_1] = '1599' or M.[M_Pull_1] = '1617' or M.[M_Pull_1] = 'Probably Private')
							and D.[Client Id] is null

							select * from #M1_Create


			--3d. Create liens CSV for M1, M3, and M5 (part 2)
					drop table #M2_Create
					
					select	[S3 ID] as ClientId, 
						Case
							When [M_Pull_2] like '1459' then 'IHS Lien'
							Else 'Military Lien - MT'
						End as 'Lientype',
						Case
							When [M_Pull_2] like '1599' then [M_Pull_2]
							When [M_Pull_2] like '1617' then [M_Pull_2]
							When [M_Pull_2] like '1459' then [M_Pull_2]
						End as 'LienholderId',
						Case
							When [M_Pull_2] like '1599' then '1214'
							When [M_Pull_2] like '1617' then '1239'
							When [M_Pull_2] like '1459' then '1214'
						End as 'CollectorId', 
							Case
								When M.Casename like '%GRG%' then 141 
								Else '338'
								End as 'AssignedUserId', 
							'To Send - EV' as 'Stage', '1' as 'StatusId', 'Yes' as 'OnBenefits', cast(getdate() as date) as 'OnBenefitsVerified',
							[Inco Name 1], [Inco Name 2], [Inco Name 3], [M_Pull_1], [M_Pull_2], [M_Pull_3], 'Group 2' as 'Group',
							[Inco Address 1], [Inco Phn # 1], [Inco Gr # 1], [Inco ID # 1], [Inco Address 2], [Inco Phone 2], [Inco Gr # 2], [Inco ID # 2], [Inco Address 3], [Inco Phone 3], [Inco Gr # 3], [Inco ID # 3], [Ticket#]
					Into	#M2_Create
					From	#MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on M.[S3 ID]=D.[Client Id]
					Where	(M.[M_Pull_2] = '1459' or M.[M_Pull_2] = '1599' or M.[M_Pull_2] = '1617' or M.[M_Pull_2] = 'Probably Private')
							and D.[Client Id] is null

							select * from #M2_Create


			--3d. Create liens CSV for M1, M3, and M5 (part 2)
				drop table #M3_Create

					select	[S3 ID] as ClientId, 
						Case
							When [M_Pull_3] like '1459' then 'IHS Lien'
							Else 'Military Lien - MT'
						End as 'Lientype',
						Case
							When [M_Pull_3] like '1599' then [M_Pull_3]
							When [M_Pull_3] like '1617' then [M_Pull_3]
							When [M_Pull_3] like '1459' then [M_Pull_3]
						End as 'LienholderId',
						Case
							When [M_Pull_3] like '1599' then '1214'
							When [M_Pull_3] like '1617' then '1239'
							When [M_Pull_3] like '1459' then '1214'
						End as 'CollectorId', 
							Case
								When M.Casename like '%GRG%' then 141 
								Else '338'
								End as 'AssignedUserId', 
							'To Send - EV' as 'Stage', '1' as 'StatusId', 'Yes' as 'OnBenefits', cast(getdate() as date) as 'OnBenefitsVerified',
							[Inco Name 1], [Inco Name 2], [Inco Name 3], [M_Pull_1], [M_Pull_2], [M_Pull_3], 'Group 3' as 'Group',
							[Inco Address 1], [Inco Phn # 1], [Inco Gr # 1], [Inco ID # 1], [Inco Address 2], [Inco Phone 2], [Inco Gr # 2], [Inco ID # 2], [Inco Address 3], [Inco Phone 3], [Inco Gr # 3], [Inco ID # 3], [Ticket#]
					Into	#M3_Create
					From	#MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on M.[S3 ID]=D.[Client Id]
					Where	(M.[M_Pull_3] = '1459' or M.[M_Pull_3] = '1599' or M.[M_Pull_3] = '1617' or M.[M_Pull_3] = 'Probably Private')
							and D.[Client Id] is null

							select * from #M3_Create

			-- Military Overview
						Drop table #TTxx

						SELECT *
						INTO	#TTxx
						FROM   #M1_Create
						UNION
						SELECT *
						FROM   #M2_Create
						UNION
						SELECT *
						FROM   #M3_Create

						Select * from #TTxx where LienholderId is not NULL



			-- Create all Military Liens (Merged) CSV
						Drop table #GGxx

						SELECT *
						INTO #GGxx
						FROM #M1_Create
						WHERE [M_Pull_1] <> 'Probably Private'
						UNION
						SELECT *
						FROM   #M2_Create
						WHERE [M_Pull_2] <> 'Probably Private'
						UNION
						SELECT *
						FROM   #M3_Create
						WHERE [M_Pull_3] <> 'Probably Private'

						Select * from #GGxx


			--3e. NewLienNote CSV for M1, M3, and M5: Get newly created Ids and leave note   
																																										
					select	F.ClientId,
							F.Id,
						case
							when zzzz.[Group] = 'Group 1' then Concat('Created lien based on claimant questionnaire. Ticket #: ', zzzz.Ticket#, '. Other information given was - Ins Name: ', [Inco Name 1], '; Address:', [Inco Address 1], '; Phone: ',[Inco Phn # 1], '; Group #: ', [Inco Gr # 1], '; ID #: ',[Inco ID # 1])
							when zzzz.[Group] = 'Group 2' then Concat('Created lien based on claimant questionnaire. Ticket #: ', zzzz.Ticket#, '. Other information given was - Ins Name: ', [Inco Name 2], '; Address:', [Inco Address 2], '; Phone: ',[Inco Phone 2], '; Group #: ', [Inco Gr # 2], '; ID #: ',[Inco ID # 2])
							when zzzz.[Group] = 'Group 3' then Concat('Created lien based on claimant questionnaire. Ticket #: ', zzzz.Ticket#, '. Other information given was - Ins Name: ', [Inco Name 3], '; Address:', [Inco Address 3], '; Phone: ',[Inco Phone 3], '; Group #: ', [Inco Gr # 3], '; ID #: ',[Inco ID # 3])
						end as 'NewLienNote'
					from	Fullproductviews as F 
								LEFT OUTER JOIN #GGxx as zzzz on zzzz.[ClientId] = F.ClientId
					where	F.createdon = cast(getdate() as date) and (F.lientype like 'military%' or f.lientype like 'ihs%')
					order by 2
			

			-- Create M2 Liens (sub: establish if really M2, outer: create columns needed for import)

				drop table #M2_Military

					select s.[S3 ID] as ClientId, 'Military Lien - MT' as 'LienType', '1599' as 'LienholderId', '1214' as 'CollectorId',
							Case
								When s.Casename like '%GRG%' then 141 
								Else '338'
							End as 'AssignedUserId', 
							'Awaiting Sponsor/Facility Information' as 'Stage', '1' as 'StatusId', 'Yes' as 'OnBenefits', cast(getdate() as date) as 'OnBenefitsVerified'
					into #M2_Military
					from (
							select M.[S3 ID], M.Casename, D.[Client Id],
								case
									when [M_Pull_1] = 'M2' then 'yes'
									when [M_Pull_1] = 'Probably Private' and [M_Pull_2] = 'M2' then 'yes'
									when [M_Pull_1] = 'Probably Private' and [M_Pull_2] = 'Probably Private' and [M_Pull_3] = 'M2' then 'yes'
								else 'no'
								end as 'Really M2?'
							from #MilitaryAnalysis_AWKCVA as M
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=M.[S3 ID]
							Where D.[Client Id] is null
							) as s
					where s.[Really M2?] = 'yes'


					select * from #M2_Military




			--3g. NewLienNote CSV for M2

					select	F.ClientId, F.Id, concat('Created lien based on claimant questionnaire. Ticket #: ', M.Ticket#, '. No military info input on questionnaire but claimant indicated they are on benefits.') as 'NewLienNote'
					from	Fullproductviews as F 
								LEFT OUTER JOIN #M2_Military as M2 on M2.[ClientId]=F.ClientId
								LEFT JOIN #MilitaryAnalysis_AWKCVA as M on M.[S3 ID] = F.ClientId
								LEFT JOIN #GGxx as G on G.[ClientId] = F.ClientId
					where	(F.CreatedOn = cast(getdate() as date) and F.LienType like 'military%')
							and G.ClientId is NULL

						
						select * from Questionnaire_AWKCVA


	--4. Private Lien Analysis
			
			--4a. Analyze private lien data on spreadsheet with instructions


							drop table #PrivateAnalysis_AWKCVA

					select *,
						case
							when [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 1] is not null and [M_Pull_1] = 'Probably Private' then 'Private 1'
							when [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'Private 2'
							when [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 1] is not null and [M_Pull_1] = 'Probably Private' then 'Private 3'
							when [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'Private 4'
							when [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 1] is not null and [M_Pull_1] = 'Probably Private' then 'Private 5'
							when [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 1] is null and [Inco Address 1] is null and [Inco Phn # 1] is null and [Inco Gr # 1] is null and [Inco ID # 1] is null then 'Private 6'
							when [M_Pull_1] = '1459' or [M_Pull_1] = '1599' or [M_Pull_1] = '1617' then 'Military'
							else 'Look Into'
						end as 'P_Pull_1',

						case
							when [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 2] is not null and [M_Pull_2] = 'Probably Private' then 'Private 1'
							When [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'Private 2'
							when [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 2] is not null and [M_Pull_2] = 'Probably Private' then 'Private 3'
							When [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'Private 4'
							when [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 2] is not null and [M_Pull_2] = 'Probably Private' then 'Private 5'
							When [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 2] is null and [Inco Address 2] is null and [Inco Phone 2] is null and [Inco Gr # 2] is null and [Inco ID # 2] is null then 'Private 6'
							when [M_Pull_2] = '1459' or [M_Pull_2] = '1599' or [M_Pull_2] = '1617' then 'Military'
						else 'Look Into'
						end as 'P_Pull_2',

						case
							when [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 3] is not null and [M_Pull_3] = 'Probably Private' then 'Private 1'
							When [Auth# To Resolve Prvt Liens?] = 'Truthy' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'Private 2'
							when [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 3] is not null and [M_Pull_3] = 'Probably Private' then 'Private 3'
							When [Auth# To Resolve Prvt Liens?] = 'Falsey' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'Private 4'
							when [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 3] is not null and [M_Pull_3] = 'Probably Private' then 'Private 5'
							When [Auth# To Resolve Prvt Liens?] = 'Blanky' and [Inco Name 3] is null and [Inco Address 3] is null and [Inco Phone 3] is null and [Inco Gr # 3] is null and [Inco ID # 3] is null then 'Private 6'
							when [M_Pull_3] = '1459' or [M_Pull_3] = '1599' or [M_Pull_3] = '1617' then 'Military'
						else 'Look Into'
						end as 'P_Pull_3'
					into #PrivateAnalysis_AWKCVA
					from #MilitaryAnalysis_AWKCVA


					select * from #PrivateAnalysis_AWKCVA



			-- Second round of private analysis


					drop table #Final_PrivateAnalysis_AWKCVA

							select distinct D.[Client Id], P.[S3 ID], P.[Casename], P.[Claimant Last Name], P.[Claimant First Name], P.[Auth# To Resolve Prvt Liens?], P.[M_Pull_1], P.[M_Pull_2], P.[M_Pull_3], P.[P_Pull_1], P.[P_Pull_2], P.[P_Pull_3], 
								case
									when [P_Pull_1] = 'Private 1' then 'Private 1'
									when [P_Pull_1] = 'Private 2' and [P_Pull_2] = 'Private 2' and [P_Pull_3] = 'Private 2' then 'Private 2'
									when [P_Pull_1] = 'Private 3' then 'Private 3'
									when [P_Pull_1] = 'Private 4' and [P_Pull_2] = 'Private 4' and [P_Pull_3] = 'Private 4' then 'Private 4'
									when [P_Pull_1] = 'Private 5' then 'Private 5'
									when [P_Pull_1] = 'Private 6' and [P_Pull_2] = 'Private 6' and [P_Pull_3] = 'Private 6' then 'Private 6'
									when [P_Pull_2] = 'Private 1' then 'Private 1'
									when [P_Pull_2] = 'Private 2' and [P_Pull_1] = 'Military' and [P_Pull_3] = 'Private 2' then 'Private 2'
									when [P_Pull_2] = 'Private 3' then 'Private 3'
									when [P_Pull_2] = 'Private 4' and [P_Pull_1] = 'Military' and [P_Pull_3] = 'Private 4' then 'Private 4'
									when [P_Pull_2] = 'Private 5' then 'Private 5'
									when [P_Pull_2] = 'Private 6' and [P_Pull_1] = 'Military' and [P_Pull_3] = 'Private 6' then 'Private 6'
									when [P_Pull_3] = 'Private 1' then 'Private 1'
									when [P_Pull_3] = 'Private 2' and [P_Pull_1] = 'Military' and [P_Pull_2] = 'Military' then 'Private 2'
									when [P_Pull_3] = 'Private 3' then 'Private 3'
									when [P_Pull_3] = 'Private 4' and [P_Pull_1] = 'Military' and [P_Pull_2] = 'Military' then 'Private 4'
									when [P_Pull_3] = 'Private 5' then 'Private 5'
									else 'Look Into'
								end as 'Real Private',
								P.[Inco Name 1], P.[Inco Name 2], P.[Inco Name 3], [Inco Address 1], P.[Inco Phn # 1], P.[Inco Gr # 1], P.[Inco ID # 1], P.[Inco Address 2], P.[Inco Phone 2], P.[Inco Gr # 2], P.[Inco ID # 2], P.[Inco Address 3], P.[Inco Phone 3], P.[Inco Gr # 3], P.[Inco ID # 3], P.[Ticket#]
							into #Final_PrivateAnalysis_AWKCVA
							from #PrivateAnalysis_AWKCVA as P
								Left Join #AllTheDiscrepancies_AWKCVA as D on D.[Client Id] = P.[S3 ID]


							select * from #Final_PrivateAnalysis_AWKCVA


						select [Private Lien Analysis], count([s3 id]) 
						from #PrivateAnalysis_AWKCVA
						Group by [Private Lien Analysis]


						select * from #Final_PrivateAnalysis_AWKCVA where [Real Private] = 'look into'


			--4b. QA: How many private liens should be created?

				--Summary: All
				select	P.[S3 ID], P.[Real Private], P.[P_Pull_1], P.[P_Pull_2], P.[P_Pull_3], P.[M_Pull_1], P.[M_Pull_2], P.[M_Pull_3], P.[Inco Name 1], P.[Inco Name 2], P.[Inco Name 3],
						D.[Issue Detail: Claimant data does not match SLAM],
						D.[Issue Detail: Duplicate Records],
						D.[Issue Detail: Scribbles?],
						D.[Issue Detail: Quest Recd already true in SLAM]
				from	#Final_PrivateAnalysis_AWKCVA as P
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]


				--Summary: Liens that need to be created
				select	P.[S3 ID], P.[Real Private],  P.[P_Pull_1], P.[P_Pull_2], P.[P_Pull_3], P.[M_Pull_1], P.[M_Pull_2], P.[M_Pull_3],P.[Inco Name 1], P.[Inco Name 2], P.[Inco Name 3],
						D.[Issue Detail: Claimant data does not match SLAM],
						D.[Issue Detail: Duplicate Records],
						D.[Issue Detail: Scribbles?],
						D.[Issue Detail: Quest Recd already true in SLAM]
				from	#Final_PrivateAnalysis_AWKCVA as P
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				where	(P.[Real Private] = 'Private 1' or P.[Real Private] = 'Private 2')
						and D.[Client Id] is null


		--4c. Create file to send to RA for private lien analysis for Private 1

				--Query to get all current SLAM data for non-governmental liens (creates temp table)
					

					drop table #PrivateSLAM_AWKCVA


				SELECT		F.ClientId as 'S3 Client Id', F.ClientFirstName, F.ClientLastName, F.Id as 'S3 Product Id', F.LienType, 
							F.LienholderName, F.LienholderId, F.CollectorName, F.CollectorId, F.LienProductStatus, F.Stage, 
							F.ClosedReason, F.FinalDemandAmount, F.CaseName, F.AssignedUserId, 
							D.[Issue Detail: Claimant data does not match SLAM],
							D.[Issue Detail: Duplicate Records],
							D.[Issue Detail: Scribbles?],
							D.[Issue Detail: Quest Recd already true in SLAM]
				INTO		#PrivateSLAM_AWKCVA
				FROM		FullProductViews as F 
								INNER JOIN #Final_PrivateAnalysis_AWKCVA as P on P.[S3 ID]=F.[ClientId]
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				WHERE		(lientype like '%Private%' or (lientype like 'Medicaid Lien - MT' and ismco = 1))
							and P.[Real Private] = 'Private 1' 
							and D.[Client Id] is null
				GROUP BY	ClientId, ClientFirstName, ClientLastName, Id, LienType, LienholderName, LienholderId, CollectorName, CollectorId, LienProductStatus, Stage, 
							ClosedReason, FinalDemandAmount, F.CaseName, AssignedUserId, D.[Issue Detail: Claimant data does not match SLAM],
							D.[Issue Detail: Duplicate Records],
							D.[Issue Detail: Scribbles?],
							D.[Issue Detail: Quest Recd already true in SLAM]
				ORDER BY	3



						select * from #PrivateSLAM_AWKCVA



				--Creates spreadsheet to send to RA
					
				SELECT		P.[S3 ID], P.[Claimant Last Name], P.[Claimant First Name], count(S.[S3 Client Id]) as 'Current SLAM non-govntl lien count', 
							P.[Auth# To Resolve Prvt Liens?], 
							P.[Inco Name 1], P.[Inco Address 1], P.[Inco Phn # 1], P.[Inco Gr # 1], P.[Inco ID # 1], '' as 'Create Lien 1', '' as 'RA Notes 1','' as 'LienHolderId 1', '' as 'CollectorId 1', '' as 'AssignedUserId 1',
							P.[Inco Name 2], P.[Inco Address 2], P.[Inco Phone 2], P.[Inco Gr # 2], P.[Inco ID # 2], '' as 'Create Lien 2', '' as 'RA Notes 2','' as 'LienHolderId 2', '' as 'CollectorId 2', '' as 'AssignedUserId 2',
							P.[Inco Name 3], P.[Inco Address 3], P.[Inco Phone 3], P.[Inco Gr # 3], P.[Inco ID # 3], '' as 'Create Lien 3', '' as 'RA Notes 3','' as 'LienHolderId 3', '' as 'CollectorId 3', '' as 'AssignedUserId 3',
							D.[Issue Detail: Claimant data does not match SLAM],
							D.[Issue Detail: Duplicate Records],
							D.[Issue Detail: Scribbles?],
							D.[Issue Detail: Quest Recd already true in SLAM]
				FROM 		#Final_PrivateAnalysis_AWKCVA as P 
								LEFT OUTER JOIN #PrivateSLAM_AWKCVA as S on P.[S3 ID]=S.[S3 Client Id]
								LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				WHERE		P.[Real Private] = 'Private 1' 
							and D.[Client Id] is null
				GROUP BY	P.[S3 ID], P.[Claimant Last Name], P.[Claimant First Name], P.[Auth# To Resolve Prvt Liens?], 
							P.[Inco Name 1], P.[Inco Address 1], P.[Inco Phn # 1], P.[Inco Gr # 1], P.[Inco ID # 1], 
							P.[Inco Name 2], P.[Inco Address 2], P.[Inco Phone 2], P.[Inco Gr # 2], P.[Inco ID # 2], 
							P.[Inco Name 3], P.[Inco Address 3], P.[Inco Phone 3], P.[Inco Gr # 3], P.[Inco ID # 3],
							D.[Issue Detail: Claimant data does not match SLAM],
							D.[Issue Detail: Duplicate Records],
							D.[Issue Detail: Scribbles?],
							D.[Issue Detail: Quest Recd already true in SLAM]
					


				--Other tab for RA with current lien data in SLAM

				select	[S3 Client Id], ClientFirstName, ClientLastName, [S3 Product Id], LienType, LienHolderName, LienholderId, CollectorName, CollectorId, LienProductStatus, Stage, ClosedReason, FinalDemandAmount, P.CaseName, AssignedUserId
				from	#PrivateSLAM_AWKCVA as P
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 Client Id]
				where	D.[Client Id] is null




				--NewClientNote for claimants who had data sent to RA

				SELECT	P.[S3 ID] as Id, CONCAT('Questionnaire Processed ',cast(getdate() as date),'. Ticket #: ', P.Ticket#, '. Claimant opted in to private lien resolution. Provided insurance info sent to RA for review ',cast(getdate() as date),'.') as NewClientNote
				FROM 	#Final_PrivateAnalysis_AWKCVA as P 
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				WHERE	P.[Real Private] = 'Private 1' 
						and D.[Client Id] is null



		--4d. Create opt-in/out CSV

			drop table #OptStatus_AWKCVA
		

				select	C.Id as 'Client Id', C.AdditionalInformation as 'Current AdditionalInfo',
						Case
							When P.[Real Private] = 'Private 4' or P.[Real Private] = 'Private 6' or P.[Real Private] = 'Private 3' or P.[Real Private] = 'Private 5' then 'Opt-Out'
							When P.[Real Private] = 'Private 1' or P.[Real Private] = 'Private 2' then 'Opt-In'
							Else 'Look Into'
							End As 'Opt In/Out',
						Case
							When (C.AdditionalInformation is not null or C.AdditionalInformation <> '') then 'Yes'
							Else 'No'
							End As 'Requires Check?',
						C.Id,
						Case
							When (C.AdditionalInformation = '' or C.AdditionalInformation is null or C.AdditionalInformation = 'NULL') and (P.[Real Private] = 'Private 3' or P.[Real Private] = 'Private 4' or P.[Real Private] = 'Private 5' or P.[Real Private] = 'Private 6') then 'Opt-Out'
							When (C.AdditionalInformation = '' or C.AdditionalInformation is null or C.AdditionalInformation = 'NULL') and (P.[Real Private] = 'Private 1' or P.[Real Private] = 'Private 2') then 'Opt-In'
							When (C.AdditionalInformation is not null or C.AdditionalInformation <> '') and (P.[Real Private] = 'Private 3' or P.[Real Private] = 'Private 4' or P.[Real Private] = 'Private 5' or P.[Real Private] = 'Private 6') then concat(AdditionalInformation, '; Opt-Out')
							When (C.AdditionalInformation is not null or C.AdditionalInformation <> '') and (P.[Real Private] = 'Private 1' or P.[Real Private] = 'Private 2') then concat(AdditionalInformation, '; Opt-In')
							Else 'Look Into'
							End As 'AdditionalInformation',
						Case
							When P.[Real Private] = 'Private 4' or P.[Real Private] = 'Private 6' or P.[Real Private] = 'Private 3' or P.[Real Private] = 'Private 5' then concat('Questionnaire Processed ',cast(getdate() as date),'. Ticket #: ', P.Ticket#, '. Claimant opted out of Private and Part C lien resolution per questionnaire. Added opt-out to additional information field.')
							when P.[Real Private] = 'Private 1'  then concat('Questionnaire Processed ',cast(getdate() as date),'. Ticket #: ', P.Ticket#, '. Claimant opted in for Private Lien Resolution. Added opt-in to additional information field.') 
							when P.[Real Private] = 'Private 2' then concat('Questionnaire Processed ',cast(getdate() as date),'. Ticket #: ', P.Ticket#, '. Claimant opted in and didn’t provide ins info. Per AWKVCA, claimant should be submitted to PLRP. Added opt-in to additional information field.') 
							Else 'Look Into'
							End as 'NewClientNote'
				into	#OptStatus_AWKCVA
				from	clients as C 
							INNER JOIN #Final_PrivateAnalysis_AWKCVA as P on P.[S3 ID]=C.Id
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				where	D.[Client Id] is null


				select * from #OptStatus_AWKCVA






		--4e. Create placeholder Private Lien - PLRP for P2


				--4e pt 1: Check for any current Private or Part C liens
						
						--Create temp table
									
									drop table #AWKCVA_P2
							
							select	
									--Claimant Questionnaire Data
									P.[S3 ID], P.[Claimant Last Name], P.[Claimant First Name], 
									--Liens currently in SLAM
									FPV.Id as LienId, FPV.LienType,
									Case
										When lientype like '%plrp%' then 'PLRP'
										Else 'Not PLRP'
										End As 'LienType_Updated'
							into	#AWKCVA_P2		
							from	#Final_PrivateAnalysis_AWKCVA as P
										LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
										LEFT OUTER JOIN FullProductViews as FPV on FPV.ClientId=P.[S3 ID]
							where 	[Real Private] = 'Private 2'
									and D.[Client Id] is null


									select * from #AWKCVA_P2
									

						--Pivot data
								
								drop table #AWKCVA_P2Pivot
							

							select sub.[S3 ID], sub.[Claimant Last Name], sub.[Claimant First Name], sum(sub.[PLRP]) as PLRP_Total, sum(sub.[Not_PLRP]) as NotPLRP_Total
							into #AWKCVA_P2Pivot
							from (
									select *
									from #AWKCVA_P2
											PIVOT (
													count(LienId) 
													for LienType_Updated 
													in ([Not_PLRP], [PLRP])
													) as LienCount
									) as sub
							group by sub.[S3 ID], sub.[Claimant Last Name], sub.[Claimant First Name]



										select * from #AWKCVA_P2Pivot



					--4e pt 2: Use the pivoted data to determine who needs liens created and make a PLRP lien for them

							select	P.[S3 ID] as ClientId, 'Private Lien - PLRP' as 'LienType', '214' as 'LienholderId', '227' as 'CollectorId', '269' as 'AssignedUserId', 'To Send - EV' as 'Stage', '1' as 'StatusId' --'Yes' as 'OnBenefits', cast(getdate() as date) as 'OnBenefitsVerified'
							From	#Final_PrivateAnalysis_AWKCVA as P
										LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
										LEFT OUTER JOIN #AWKCVA_P2Pivot as Piv on Piv.[S3 ID]=P.[S3 ID]
							Where	P.[Real Private] = 'Private 2'
									and D.[Client Id] is null
									and Piv.PLRP_Total = 0



		--4f. NewLienNote CSV for P2: Get newly created Ids and leave note (from 4e)

				select	--F.ClientId, 
						F.Id, concat('Created lien based on claimant questionnaire. Ticket #: ', P.Ticket#, '. Questionnaire Processed ',cast(getdate() as date),'. Claimant opted in and didn’t provide ins info. Per AWKO, claimant should be submitted to Rawlings PLRP.') as 'NewLienNote'
				from	Fullproductviews as F 
							LEFT OUTER JOIN #Final_PrivateAnalysis_AWKCVA as P on P.[S3 ID]=F.ClientId
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
				Where	[Real Private] = 'Private 2'
						and F.CreatedOn = cast(getdate() as date) and F.LienType like 'Private Lien - PLRP'
						and D.[Client Id] is null




		--4g. NewLienNote CSV for P2 where claimant already had a Private/PLRP lien (from 4e)

				select	F.Id, concat('Created lien based on claimant questionnaire. Ticket #: ', P.Ticket#, '. Questionnaire Processed ',cast(getdate() as date),'. Claimant opted in and didn’t provide ins info. Per AWKO, claimant should be submitted to Rawlings PLRP. Claimant previously submitted to PLRP.') as 'NewLienNote'
				from	Fullproductviews as F 
							LEFT OUTER JOIN #Final_PrivateAnalysis_AWKCVA as P on P.[S3 ID]=F.ClientId
							LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=F.ClientId
							LEFT OUTER JOIN #AWKCVA_P2Pivot as Piv on Piv.[S3 ID]=F.ClientId
				Where	P.[Real Private] = 'Private 2'
						and D.[Client Id] is null
						and Piv.PLRP_Total > 0
						and F.LienType like '%PLRP%'



	-- Private Opt Match 
			drop table #PrivateOptMatch_AWKCVA

				select 	s.ClientId, s.[Lien Id],
					case
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%plrp%' and s.[To-Do] like 'Update - Need to re-open lien' then 'To Send - EV'
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%private%' and s.[To-Do] like 'Update - Need to re-open lien' then 'To Send - Claims Request'
						when (s.[Real Private] like 'Private 3' or s.[Real Private] like 'Private 4' or s.[Real Private] like 'Private 5' or s.[Real Private] like 'Private 6') and s.[To-Do] like 'Update to Closed – Per Attorney Request' then 'Closed - Per Attorney Request'
						else ''
					end as 'stage',
					case
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%plrp%' and s.[To-Do] like 'Update - Need to re-open lien' then ''
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%private%' and s.[To-Do] like 'Update - Need to re-open lien' then 'Yes'
						else ''
					end as 'onbenefits',
					case 
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%plrp%' and s.[To-Do] like 'Update - Need to re-open lien' then ''
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.Lientype like '%private%' and s.[To-Do] like 'Update - Need to re-open lien' then cast(getdate() as date)
						else ''
					end as 'onbenefitsverified',
					case
						when (s.[Real Private] like 'Private 1' or s.[Real Private] like 'Private 2') and s.[To-Do] like 'Update - Need to re-open lien' then concat('Re-opened lien based on questionnaire instructions. Client opted-in to private insurance. Ticket #: ', s.Ticket#)
						when (s.[Real Private] like 'Private 3' or s.[Real Private] like 'Private 4' or s.[Real Private] like 'Private 5' or s.[Real Private] like 'Private 6') and s.[To-Do] like 'Update to Closed – Per Attorney Request' then concat('Claimant opted out of Private and Part C lien resolution per questionnaire. Ticket #: ', s.Ticket#)
						else 'All Good'
					end as 'newliennote',
					s.LienType, s.lienstage, s.lienproductstatus, s.statusid, s.[Opt In/Out], s.[Real Private]
				into #PrivateOptMatch_AWKCVA
				from(
							select F.ClientId, F.Id as 'Lien Id', F.LienType, F.stage as 'lienstage', F.lienproductstatus, F.statusid, O.[Opt In/Out], P.[Real Private], P.[Ticket#],
								case
									when F.[lienproductstatus] like 'Open' and [Opt In/Out] like 'Opt-In' then 'All Good'
									when F.[lienproductstatus] like 'Open' and [Opt In/Out] like 'Opt-Out' then 'Update to Closed – Per Attorney Request'
									when F.[lienproductstatus] like 'Closed%' and [Opt In/Out] like 'Opt-In' then 'Update - Need to re-open lien'
									when F.[lienproductstatus] like 'Open' and [Opt In/Out] like 'Opt-In' then 'All Good'
									else 'look into'
								end as 'To-Do'
							from FullProductViews as F
									join #OptStatus_AWKCVA as O on O.[ID] = F.ClientId
									join #Final_PrivateAnalysis_AWKCVA as P on P.[S3 ID] = F.ClientId
							where lientype like '%private%'
							) as s



					select * from #PrivateOptMatch_AWKCVA where newliennote <> 'All Good'



		--4g. Gather Part C data to send to Cathy for review

					drop table #PartCEntitlement_AWKCVA


				--Check: Does anyone in the batch have a Part C lien?

					select ClientId, Id, LienType
					from FullProductViews as F
							join Questionnaire_AWKCVA as Q on Q.[S3 ID]=F.ClientId
					where lientype like '%part c%'



			--Main Query
				
				select	ClientId, 
						Case
							When Lientype = 'Medicare - Global' and PartCEntitlementStart is null and OnBenefits = 'Yes' then 'Not entitled for Part C'
							When Lientype = 'Medicare - Global' and PartCEntitlementStart is not null and OnBenefits = 'Yes' then 'Entitled for Part C'
							When Lientype = 'Medicare - Global' and OnBenefits = 'No' then 'FNE for Medicare'
							When Lientype = 'Medicare - Global' and OnBenefits is null then 'No response from Medicare yet'
							Else 'Look Into'
							End As 'Detail for CE - Part C Entitlement'
				Into	#PartCEntitlement_AWKCVA
				From	FullProductViews
				Where	Lientype = 'Medicare - Global' and CaseId in (2770,2741)



				select	sub.*, 
						Case
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-In' and sub.[Detail for CE - Part C Entitlement] = 'Not entitled for Part C' then 'No action - there should not be Part C liens if the claimant has no Part C Entitlement Dates'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-In' and sub.[Detail for CE - Part C Entitlement] = 'Entitled for Part C' then 'Open any Part C liens in SLAM'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-In' and sub.[Detail for CE - Part C Entitlement] = 'FNE for Medicare' then 'No action - there should not be Part C liens if the claimant is FNE for Mcare'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-In' and sub.[Detail for CE - Part C Entitlement] = 'No response from Medicare yet' then 'No action - keep any Part C liens at hold'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-Out' and sub.[Detail for CE - Part C Entitlement] = 'Not entitled for Part C' then 'No action - there should not be Part C liens if the claimant has no Part C Entitlement Dates'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-Out' and sub.[Detail for CE - Part C Entitlement] = 'Entitled for Part C' then 'Close any Part C liens in SLAM'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-Out' and sub.[Detail for CE - Part C Entitlement] = 'FNE for Medicare' then 'No action - there should not be Part C liens if the claimant is FNE for Mcare'
							When sub.[Opt In/Out based on Questionnaire] = 'Opt-Out' and sub.[Detail for CE - Part C Entitlement] = 'No response from Medicare yet' then 'No action - keep any Part C liens at hold'
							Else 'Look Into'
							End as 'Things for CE to do'					
				from	(
								select	P.[S3 ID],F.Id as 'Lien Id', F.LienProductStatus, F.LienType, P.[Claimant Last Name], P.[Claimant First Name], P.[Real Private], F.AdditionalInformation,
										Case
											When P.[Real Private] = 'Private 3' or P.[Real Private] = 'Private 5' then 'Discrepancy'
											When P.[Real Private] = 'Private 4' or P.[Real Private] = 'Private 6' then 'Opt-Out'
											When P.[Real Private] = 'Private 1' or P.[Real Private] = 'Private 2' then 'Opt-In'
											Else 'Look Into'
											End As 'Opt In/Out based on Questionnaire',
										C.[Detail for CE - Part C Entitlement]
								from	#Final_PrivateAnalysis_AWKCVA as P 
											LEFT OUTER JOIN FullProductViews as F on F.[ClientId]=P.[S3 ID]
											LEFT OUTER JOIN #PartCEntitlement_AWKCVA as C on C.[ClientId]=P.[S3 ID]
											LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=P.[S3 ID]
								where	D.[Client Id] is null
										and F.LienType like '%Part C%'
					
							) as sub






	--5. CSV to update Questionnaire Rec'd to be True

			SELECT	Q.[S3 ID] as 'ClientId', C.QuestionnaireReceived as 'Current QuestionnaireReceived', C.Id, 
					Case
						When C.QuestionnaireReceived = '' or C.QuestionnaireReceived is null then 'True'
						Else 'Look Into'
						End As 'QuestionnaireReceived', 
					concat('Updated Questionnaire Receieved to be true. Ticket #: ', Q.Ticket#) as 'NewClientNote'

			FROM	Questionnaire_AWKCVA as Q 
						LEFT OUTER JOIN Clients as C on Q.[S3 ID]=C.Id 
						LEFT OUTER JOIN #AllTheDiscrepancies_AWKCVA as D on D.[Client Id]=Q.[S3 ID]
						LEFT OUTER JOIN #Final_PrivateAnalysis_AWKCVA as P on Q.[S3 ID]=P.[S3 Id]
			WHERE	D.[Client Id] is null
					--Data sent to RA
					and P.[Real Private] <> 'Private 1'