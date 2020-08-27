--drop table QuestionnaireCode_ReferenceTable

select * from QuestionnaireCode_ReferenceTable
order by Case_Letters



-- Update case after writing a query for the case ----------------------------------------
update QuestionnaireCode_ReferenceTable
set [Has_Query] = 'Yes'
where Query_Letters = 'AWKCV'



-- Query to check if I've met the 2020 Goal ----------------------------------------------
select T.*,
	Case
		When ((Has_Query like 'No') AND (Total_Claimants > 500) AND (Percent_Complete < 75)) then 'Needs a Query Written'
		Else 'All Good in the Hood'
	End as 'Query Status'
from(
		select S.Query_Letters, S.Has_Query, (round(cast(S.Questionnaire_Count as float) / cast(S.Total_Claimants as float), 2)*100) as Percent_Complete, S.Total_Claimants, (cast(S.Total_Claimants as float) - cast(S.Questionnaire_Count as float)) as 'Claimants_Left'
		from (
				select sub.Query_Letters, sub.Has_Query, count(sub.questionnairereceived) as Questionnaire_Count, count(sub.id) as Total_Claimants
				from (
						select r.*, c.caseid, c.id, c.questionnairereceived
						from clients as c
							left join QuestionnaireCode_ReferenceTable as r on r.Case_Id = c.CaseId
						where r.Case_Id is not Null
						) as sub
				group by sub.Query_Letters, sub.Has_Query
				) as S
		) as T
order by Has_Query, Claimants_Left desc
