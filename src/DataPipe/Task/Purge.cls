Class DataPipe.Task.Purge Extends %SYS.Task.Definition
{

Parameter TaskName = "DataPipe.Task.Purge";

/// Number of days to keep in the database
Property DaysToKeep As %Integer [ InitialExpression = 30 ];

/// Number of datys to keep errors in the database
Property DaysToKeepErrors As %Integer [ InitialExpression = 90 ];

/// Task
Method OnTask() As %Status
{
    set ret = $$$OK
    try {
        do ..Log("=====================================")
		do ..Log("*DataPipe.Task.Purge Begin")
        $$$ThrowOnError(..DeleteData(..DaysToKeep, ..DaysToKeepErrors))
        do ..Log("*DataPipe.Task.Purge End")

    } catch ex {
        set ret = ex.AsStatus()
        do ..Log("<ERROR> OnTask: "_$system.Status.GetOneErrorText(ret))
    }
    quit ret
}

/// Purge DataPipe data. Keeps data generated in the last <i>DaysToKeep</i> days if ignored or done. Keeps data generated in the last <i>DaysToKeeErrors</i> days if not ignored and not done.
/// Param <b>pDaysToKeep</b>: Number of days to keep in the database
/// Param <b>pDaysToKeepErrors</b>: Number of days to keep errors in the database
/// Examples: 
///   do ##class(DataPipe.Task.Purge).DeleteData(0, 0) ; delete all data
///   do ##class(DataPipe.Task.Purge).DeleteData(1, 20) ; keep 1 day of data and 20 days of data with errors
ClassMethod DeleteData(pDaysToKeep As %Integer = 30, pDaysToKeepErrors As %Integer = 90) As %Status
{
    set ret = $$$OK
    set %tDoNotDeleteDate = $zdate(+$horolog - pDaysToKeep, 3)_" 23:59:59"
    set %tDoNotDeleteErrorsDate = $zdate(+$horolog - pDaysToKeepErrors, 3)_" 23:59:59"

    try {
        set (ntotal, ndeleted) = 0

        set select = "select ID "
        set from = "from DataPipe_Data.Inbox "
        set where = "where (CreatedTS < ? and (Ignored = 1 or Status = 'DONE')) " _
                    "or (CreatedTS < ? and Status != 'DONE') "
        set orderBy = "order by CreatedTS, ID "

        set sql = select _ from _ where _ orderBy

        set statement = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(statement.%Prepare(sql))

        set result = statement.%Execute(%tDoNotDeleteDate, %tDoNotDeleteErrorsDate)
        while result.%Next() {
            
            set id = result.%Get("ID")
            set inboxItem = ##class(DataPipe.Data.Inbox).%OpenId(id)

            // delete Ingestions->Stagings->Opers
            $$$ThrowOnError(..DeleteIngestions(inboxItem.Ingestions))
            // delete Inbox
            $$$ThrowOnError(##class(DataPipe.Data.Inbox).%DeleteId(inboxItem.%Id()))
            set ndeleted = ndeleted + 1
        }
        do ..Log("Total="_ntotal_", Deleted="_ndeleted_$$$NL)

    } catch ex {
        set ret = ex.AsStatus()
        do ..Log("<ERROR> DeleteData: "_$system.Status.GetOneErrorText(ret))
    }
    quit ret
}

/// Delete ingestions and related objects (Ingestions->Stagings->Opers)
ClassMethod DeleteIngestions(ingestions As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Ingestion")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {
        for i = 1:1:ingestions.Count() {
            set ingestion = ingestions.GetAt(i)
            if $isobject(ingestion) {
                $$$ThrowOnError(..DeleteStagings(ingestion.Stagings))
				$$$ThrowOnError(##class(DataPipe.Data.Ingestion).%DeleteId(ingestion.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Delete Stagings and related objects (Stagings->Opers)
ClassMethod DeleteStagings(stagings As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Staging")) As %Status [ Private ]
{
    set tSC = $$$OK
    try {
        for i = 1: 1: stagings.Count() {
            set staging = stagings.GetAt(i)
            if $isobject(staging) {
                $$$ThrowOnError(..DeleteOperations(staging.Opers))
				$$$ThrowOnError(##class(DataPipe.Data.Staging).%DeleteId(staging.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Delete Opers
ClassMethod DeleteOperations(operations As %RelationshipObject(ELEMENTTYPE="DataPipe.Data.Oper")) As %Status [ Private ]
{
    set tSC = $$$OK

    try {
        for i = 1: 1: operations.Count() {
            set operation = operations.GetAt(i)
            if $isobject(operation) {
				$$$ThrowOnError(##class(DataPipe.Data.Oper).%DeleteId(operation.%Id()))
            }
        }
    } catch ex {
        set tSC = ex.AsStatus()
    }

    quit tSC
}

/// Log a text message
ClassMethod Log(
	pText As %String,
	ByRef pInfo)
{
	set tText = $zdt($h,3)_": "_pText
	write !,tText
	zwrite:$d(pInfo) pInfo
}

}
